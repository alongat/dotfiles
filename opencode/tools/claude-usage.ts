import { Database } from "bun:sqlite"
import { homedir } from "os"
import { join } from "path"

const DB_PATH = join(homedir(), ".local/share/opencode/opencode.db")

interface SessionRow {
  cost: number
  tokens_input: number
  tokens_output: number
  tokens_reasoning: number
  tokens_cache_read: number
  tokens_cache_write: number
  model: string | null
  time_created: number
}

function formatCost(n: number): string {
  return `$${n.toFixed(2)}`
}

function formatTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${(n / 1_000).toFixed(0)}k`
  return String(n)
}

function monthRange(year: number, month: number): { start: number; end: number } {
  // month is 1-based
  const start = new Date(year, month - 1, 1).getTime()
  const end = new Date(year, month, 1).getTime()
  return { start, end }
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

      results.push("## Claude Usage Report\n")

      // --- Per-month summary ---
      results.push("### Monthly Summary\n")
      results.push("| Month | Cost | Sessions | Input | Output | Cache Read |")
      results.push("|-------|------|----------|-------|--------|------------|")

      for (let i = 0; i < numMonths; i++) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
        const year = d.getFullYear()
        const month = d.getMonth() + 1
        const { start, end } = monthRange(year, month)

        const row = db
          .query<
            {
              cost: number
              sessions: number
              tokens_input: number
              tokens_output: number
              tokens_cache_read: number
            },
            [number, number]
          >(
            `SELECT
              COALESCE(SUM(cost), 0) AS cost,
              COUNT(*) AS sessions,
              COALESCE(SUM(tokens_input), 0) AS tokens_input,
              COALESCE(SUM(tokens_output), 0) AS tokens_output,
              COALESCE(SUM(tokens_cache_read), 0) AS tokens_cache_read
            FROM session
            WHERE time_created >= ? AND time_created < ?
              AND (parent_id IS NULL OR parent_id = '')`
          )
          .get(start, end)

        if (!row) continue

        const label = d.toLocaleString("default", { month: "short", year: "numeric" })
        const current = i === 0 ? " *(current)*" : ""
        results.push(
          `| ${label}${current} | ${formatCost(row.cost)} | ${row.sessions} | ${formatTokens(row.tokens_input)} | ${formatTokens(row.tokens_output)} | ${formatTokens(row.tokens_cache_read)} |`
        )
      }

      // --- Current month model breakdown ---
      const { start: thisStart, end: thisEnd } = monthRange(now.getFullYear(), now.getMonth() + 1)

      const modelRows = db
        .query<
          { model: string | null; cost: number; sessions: number },
          [number, number]
        >(
          `SELECT
            model,
            COALESCE(SUM(cost), 0) AS cost,
            COUNT(*) AS sessions
          FROM session
          WHERE time_created >= ? AND time_created < ?
            AND (parent_id IS NULL OR parent_id = '')
          GROUP BY model
          ORDER BY cost DESC`
        )
        .all(thisStart, thisEnd)

      if (modelRows.length > 0) {
        results.push("\n### This Month by Model\n")
        results.push("| Model | Cost | Sessions |")
        results.push("|-------|------|----------|")

        for (const r of modelRows) {
          let modelName = "unknown"
          if (r.model) {
            try {
              const parsed = JSON.parse(r.model) as { id?: string; providerID?: string }
              modelName = parsed.id ?? modelName
            } catch {
              modelName = r.model
            }
          }
          results.push(`| ${modelName} | ${formatCost(r.cost)} | ${r.sessions} |`)
        }
      }

      // --- Current month daily breakdown (last 7 days) ---
      const sevenDaysAgo = now.getTime() - 7 * 24 * 60 * 60 * 1000
      const dailyRows = db
        .query<{ day: string; cost: number; sessions: number }, [number, number]>(
          `SELECT
            date(time_created / 1000, 'unixepoch', 'localtime') AS day,
            COALESCE(SUM(cost), 0) AS cost,
            COUNT(*) AS sessions
          FROM session
          WHERE time_created >= ? AND time_created < ?
            AND (parent_id IS NULL OR parent_id = '')
          GROUP BY day
          ORDER BY day DESC
          LIMIT 7`
        )
        .all(sevenDaysAgo, thisEnd)

      if (dailyRows.length > 0) {
        results.push("\n### Last 7 Days\n")
        results.push("| Date | Cost | Sessions |")
        results.push("|------|------|----------|")
        for (const r of dailyRows) {
          results.push(`| ${r.day} | ${formatCost(r.cost)} | ${r.sessions} |`)
        }
      }

      // --- All-time totals ---
      const allTime = db
        .query<{ cost: number; sessions: number }, []>(
          `SELECT COALESCE(SUM(cost), 0) AS cost, COUNT(*) AS sessions
           FROM session
           WHERE parent_id IS NULL OR parent_id = ''`
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
