import type { Plugin } from "@opencode-ai/plugin"
import { Database } from "bun:sqlite"
import { homedir } from "os"
import { join } from "path"

const DB_PATH = join(homedir(), ".local/share/opencode/opencode.db")

const TOAST_COOLDOWN_MS = 4 * 60 * 60 * 1000 // 4 hours
let lastToastAt = 0

function formatCost(n: number): string {
  return `$${n.toFixed(2)}`
}

export const UsageToastPlugin: Plugin = async ({ client }) => {
  return {
    event: async ({ event }) => {
      // Fire when the agent finishes working, not on session start
      if (event.type !== "session.idle") return

      // session.idle carries sessionID — skip if missing (safety)
      const sessionID = (event.properties as { sessionID?: string }).sessionID
      if (!sessionID) return

      const nowMs = Date.now()
      if (nowMs - lastToastAt < TOAST_COOLDOWN_MS) return
      lastToastAt = nowMs

      try {
        const db = new Database(DB_PATH, { readonly: true })
        const now = new Date()

        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime()
        const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1).getTime()

        // Monthly total from message table — includes all sessions (subagents too)
        const row = db
          .query<{ cost: number; sessions: number }, [number, number]>(
            `SELECT
              COALESCE(SUM(CAST(json_extract(data, '$.cost') AS REAL)), 0) AS cost,
              COUNT(DISTINCT session_id) AS sessions
            FROM message
            WHERE json_extract(data, '$.role') = 'assistant'
              AND time_created >= ? AND time_created < ?`
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
        // Never break the session over a usage toast
      }
    },
  }
}
