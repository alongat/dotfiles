// rex-agents plugin for OpenCode: reports this tab's session to `rex-agents hook` in the same
// JSON shape Claude Code and Codex hooks use, so one record format covers all three agents.
//
// Loaded from ~/.config/opencode/plugins (a symlink to the dotfiles opencode/plugins dir).
// Does nothing unless the process runs inside a Rex block (REX_BLOCK set) and owns the
// terminal (`opencode` TUI or `opencode run`; not `serve`, `web` or `attach`). herdr panes
// are skipped, as in rex-agents' own hook.
import { execFile } from "node:child_process";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";

const AGENT = "opencode";
const HOOK_BIN = process.env.REX_AGENTS_BIN || path.join(os.homedir(), ".dotfiles", "rex", "bin", "rex-agents");

function ownsTerminal() {
  const args = process.argv.slice(2);
  const sep = args.indexOf("--");
  if (sep !== -1) args.splice(sep);
  if (args.some((a) => a === "--attach" || a.startsWith("--attach="))) return false;
  while (args[0] === "--print-logs" || args[0] === "--log-level" || args[0]?.startsWith("--log-level=")) {
    args.splice(0, args[0] === "--log-level" ? 2 : 1);
  }
  return !["serve", "web", "attach", "acp"].includes(args[0]);
}

function enabled() {
  return Boolean(process.env.REX_BLOCK) && process.env.HERDR_ENV !== "1" && ownsTerminal();
}

function modelName(model) {
  if (!model) return undefined;
  if (typeof model === "string") return model;
  if (model.providerID && model.modelID) return `${model.providerID}/${model.modelID}`;
  return undefined;
}

function textOf(parts) {
  return (parts || [])
    .filter((p) => p && p.type === "text" && typeof p.text === "string")
    .map((p) => p.text)
    .join("\n")
    .trim();
}

export const RexAgentsPlugin = async ({ client, directory }) => {
  if (!enabled()) return {};

  let chain = Promise.resolve();
  let root = process.env.REX_AGENT_SESSION || undefined; // set by rex-agent when resuming
  let model;
  const parents = new Map(); // child session id -> parent id

  function payload(event, fields) {
    return {
      hook_event_name: event,
      agent: AGENT,
      session_id: root,
      cwd: directory,
      model,
      ...fields,
    };
  }

  // Events are queued so the record sees them in order; a hook that fails never affects the agent.
  function emit(event, fields = {}) {
    const body = JSON.stringify(payload(event, fields));
    chain = chain
      .then(
        () =>
          new Promise((resolve) => {
            const child = execFile(HOOK_BIN, ["hook"], { env: process.env, timeout: 5000 }, () => resolve());
            child.stdin.on("error", () => {});
            child.stdin.end(body);
          }),
      )
      .catch(() => {});
    return chain;
  }

  function emitSync(event, fields = {}) {
    try {
      spawnSync(HOOK_BIN, ["hook"], { input: JSON.stringify(payload(event, fields)), env: process.env, timeout: 3000 });
    } catch {}
  }

  function rootOf(id) {
    const seen = new Set();
    while (id && parents.has(id) && !seen.has(id)) {
      seen.add(id);
      id = parents.get(id);
    }
    return id;
  }

  async function lastAssistantText(sessionID) {
    try {
      const res = await client.session.messages({ path: { id: sessionID } });
      const messages = res?.data || [];
      for (let i = messages.length - 1; i >= 0; i--) {
        const m = messages[i];
        if (m?.info?.role === "assistant") {
          const text = textOf(m.parts);
          if (text) return text;
        }
      }
    } catch {}
    return undefined;
  }

  // The process is going away: SIGHUP when Rex dies or the tab closes, SIGTERM/SIGINT on a clean
  // shutdown. The hook decides "ended" vs "interrupted" by whether a Rex server still answers.
  let ending = false;
  function onSignal(signal) {
    if (ending) return;
    ending = true;
    emitSync("SessionEnd", { reason: "other", signal });
    if (process.listenerCount(signal) <= 1) process.exit(128 + (signal === "SIGHUP" ? 1 : signal === "SIGINT" ? 2 : 15));
  }
  for (const sig of ["SIGHUP", "SIGTERM", "SIGINT"]) process.on(sig, () => onSignal(sig));
  process.on("exit", () => {
    if (ending) return;
    ending = true;
    emitSync("SessionEnd", { reason: "exit" });
  });

  if (root) emit("SessionStart", { source: "resume" });

  return {
    "chat.message": async (input, output) => {
      const id = input?.sessionID;
      if (!id) return;
      if (parents.has(id)) return; // a subagent's prompt, not the user's
      if (id !== root) {
        // first prompt of a fresh session, or the user switched sessions in the TUI
        root = id;
        await emit("SessionStart", { source: "startup" });
      }
      model = modelName(input.model) || model;
      await emit("UserPromptSubmit", { prompt: textOf(output?.parts).slice(0, 500) });
    },
    event: async ({ event }) => {
      const type = event?.type;
      const p = event?.properties || {};
      const info = p.info;
      if (info?.id && info.parentID) parents.set(info.id, info.parentID);
      const id = p.sessionID || info?.id;
      switch (type) {
        case "session.created":
          if (!root && info?.id && !info.parentID) {
            root = info.id;
            await emit("SessionStart", { source: "startup" });
          }
          break;
        case "session.idle":
          if (id && rootOf(id) === root && id === root) {
            await emit("Stop", { last_assistant_message: await lastAssistantText(root) });
          }
          break;
        case "session.error":
          if (id && id === root) await emit("Stop", { error: true, last_assistant_message: await lastAssistantText(root) });
          break;
        case "permission.asked":
        case "question.asked":
          if (id && rootOf(id) === root) {
            const what = p.title || p.permission || p.type || type;
            await emit("Notification", { notification_type: "permission_prompt", message: String(what).slice(0, 500) });
          }
          break;
        case "permission.replied":
        case "question.replied":
        case "question.rejected":
          if (id && rootOf(id) === root) await emit("PostToolUse", { tool_name: type });
          break;
        default:
          break;
      }
    },
  };
};

export default RexAgentsPlugin;
