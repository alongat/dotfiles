import type { Plugin } from "@opencode-ai/plugin"
import { Database } from "bun:sqlite"
import { homedir } from "os"
import { join } from "path"

const DB_PATH = join(homedir(), ".local/share/opencode/opencode.db")

function formatCost(n: number): string {
  return `$${n.toFixed(2)}`
}

export const UsageToastPlugin: Plugin = async ({ client }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.created") return

      try {
        const db = new Database(DB_PATH, { readonly: true })
        const now = new Date()

        // Start of current month in ms
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime()
        // Start of next month in ms
        const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1).getTime()

        const row = db
          .query<{ cost: number; sessions: number }, [number, number]>(
            `SELECT
              COALESCE(SUM(cost), 0) AS cost,
              COUNT(*) AS sessions
            FROM session
            WHERE time_created >= ? AND time_created < ?
              AND (parent_id IS NULL OR parent_id = '')`
          )
          .get(monthStart, monthEnd)

        db.close()

        if (!row) return

        const monthLabel = now.toLocaleString("default", { month: "short" })
        const message = `${monthLabel} Claude usage: ${formatCost(row.cost)} · ${row.sessions} sessions`

        await client.tui.showToast({
          body: { message, variant: "info" },
        })
      } catch {
        // Never break session startup over a usage toast
      }
    },
  }
}
