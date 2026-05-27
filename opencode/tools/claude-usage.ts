import { Database } from "bun:sqlite"
import { homedir } from "os"
import { join } from "path"

const DB_PATH = join(homedir(), ".local/share/opencode/opencode.db")

function formatCost(n: number): string {
  return `$${n.toFixed(2)}`
}

function formatTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${(n / 1_000).toFixed(0)}k`
  return String(n)
}

export default {
  description:
    "Show Claude API usage statistics from the local OpenCode database. Returns monthly cost, token counts, session counts, per-model breakdown, and daily trend over the past 3 months. Useful for tracking spending.",
  args: {},
  async execute() {
    const db = new Database(DB_PATH, { readonly: true })

    try {
      const numMonths = 3
      const now = new Date()
      const results: string[] = []

      // Start of the earliest month we care about (ms)
      const windowStart = new Date(now.getFullYear(), now.getMonth() - (numMonths - 1), 1).getTime()
      // Start of next month (ms) — used as exclusive upper bound for current month
      const nextMonthStart = new Date(now.getFullYear(), now.getMonth() + 1, 1).getTime()

      results.push("## Claude Usage Report\n")

      // -----------------------------------------------------------------------
      // Monthly summary — message table, all sessions including subagents
      // -----------------------------------------------------------------------
      results.push("### Monthly Summary\n")
      results.push("| Month | Cost | Sessions | Input | Output | Cache Read |")
      results.push("|-------|------|----------|-------|--------|------------|")

      type MonthRow = {
        month: string
        cost: number
        sessions: number
        tokens_input: number
        tokens_output: number
        tokens_cache_read: number
      }

      const monthRows = db
        .query<MonthRow, [number]>(
          `SELECT
            strftime('%Y-%m', time_created / 1000, 'unixepoch', 'localtime') AS month,
            COALESCE(SUM(CAST(json_extract(data, '$.cost') AS REAL)), 0) AS cost,
            COUNT(DISTINCT session_id) AS sessions,
            COALESCE(SUM(CAST(json_extract(data, '$.tokens.input') AS INTEGER)), 0) AS tokens_input,
            COALESCE(SUM(CAST(json_extract(data, '$.tokens.output') AS INTEGER)), 0) AS tokens_output,
            COALESCE(SUM(CAST(json_extract(data, '$.tokens.cache.read') AS INTEGER)), 0) AS tokens_cache_read
          FROM message
          WHERE json_extract(data, '$.role') = 'assistant'
            AND time_created >= ?
          GROUP BY month
          ORDER BY month DESC
          LIMIT 3`
        )
        .all(windowStart)

      for (const row of monthRows) {
        const [year, mon] = row.month.split("-").map(Number)
        const d = new Date(year, mon - 1, 1)
        const label = d.toLocaleString("default", { month: "short", year: "numeric" })
        const isCurrent = row.month === `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`
        const tag = isCurrent ? " *(current)*" : ""
        results.push(
          `| ${label}${tag} | ${formatCost(row.cost)} | ${row.sessions} | ${formatTokens(row.tokens_input)} | ${formatTokens(row.tokens_output)} | ${formatTokens(row.tokens_cache_read)} |`
        )
      }

      // -----------------------------------------------------------------------
      // Current month by model — message table
      // -----------------------------------------------------------------------
      const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime()

      type ModelRow = {
        provider: string | null
        model: string | null
        cost: number
        sessions: number
      }

      const modelRows = db
        .query<ModelRow, [number, number]>(
          `SELECT
            json_extract(data, '$.providerID') AS provider,
            json_extract(data, '$.modelID') AS model,
            COALESCE(SUM(CAST(json_extract(data, '$.cost') AS REAL)), 0) AS cost,
            COUNT(DISTINCT session_id) AS sessions
          FROM message
          WHERE json_extract(data, '$.role') = 'assistant'
            AND time_created >= ? AND time_created < ?
          GROUP BY provider, model
          ORDER BY cost DESC`
        )
        .all(thisMonthStart, nextMonthStart)

      if (modelRows.length > 0) {
        results.push("\n### This Month by Model\n")
        results.push("| Model | Cost | Sessions |")
        results.push("|-------|------|----------|")

        for (const r of modelRows) {
          const label = r.model ?? r.provider ?? "unknown"
          results.push(`| ${label} | ${formatCost(r.cost)} | ${r.sessions} |`)
        }
      }

      // -----------------------------------------------------------------------
      // Last 7 days — message table
      // -----------------------------------------------------------------------
      const sevenDaysAgo = now.getTime() - 7 * 24 * 60 * 60 * 1000

      type DayRow = { day: string; cost: number; sessions: number }

      const dailyRows = db
        .query<DayRow, [number]>(
          `SELECT
            date(time_created / 1000, 'unixepoch', 'localtime') AS day,
            COALESCE(SUM(CAST(json_extract(data, '$.cost') AS REAL)), 0) AS cost,
            COUNT(DISTINCT session_id) AS sessions
          FROM message
          WHERE json_extract(data, '$.role') = 'assistant'
            AND time_created >= ?
          GROUP BY day
          ORDER BY day DESC
          LIMIT 7`
        )
        .all(sevenDaysAgo)

      if (dailyRows.length > 0) {
        results.push("\n### Last 7 Days\n")
        results.push("| Date | Cost | Sessions |")
        results.push("|------|------|----------|")
        for (const r of dailyRows) {
          results.push(`| ${r.day} | ${formatCost(r.cost)} | ${r.sessions} |`)
        }
      }

      // -----------------------------------------------------------------------
      // All-time totals — message table
      // -----------------------------------------------------------------------
      const allTime = db
        .query<{ cost: number; sessions: number }, []>(
          `SELECT
            COALESCE(SUM(CAST(json_extract(data, '$.cost') AS REAL)), 0) AS cost,
            COUNT(DISTINCT session_id) AS sessions
          FROM message
          WHERE json_extract(data, '$.role') = 'assistant'`
        )
        .get()

      if (allTime) {
        results.push(`\n---\n**All-time:** ${formatCost(allTime.cost)} across ${allTime.sessions} sessions`)
      }

      return results.join("\n")
    } finally {
      db.close()
    }
  },
}
