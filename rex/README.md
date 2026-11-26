# rex-agents

Coding agents (Claude Code, Codex, OpenCode) that run in Rex tabs and survive a Rex server
restart, plus a CLI for starting subagents as Rex tabs instead of a built-in subagent tool.

Rex is superlogical's closed-source multiplexer. It already snapshots every session, window
and block, and brings each block back with the same block ID and cwd when the server
restarts. It does not replay the block's command (the server log says
`not replaying creation options on restore dropped=[command]`), so a restored agent tab is a
plain login shell with `REX_BLOCK` set. These scripts turn that shell back into the agent
without touching Rex itself.

## Pieces

| file | role |
|---|---|
| `bin/rex-agent` | block command. Looks up its own block in the state store and runs the agent fresh, resumes its session, or marks the record broken and leaves a shell. |
| `bin/rex-agents` | CLI and hook consumer: `list`, `status`, `spawn`, `send`, `result`, `wait`, `restore`, `rm`; `install-hooks` and `codex-trust` for setup. |
| `opencode/rex-agents.js` | OpenCode plugin (linked from `opencode/plugins/`). Translates OpenCode events into the same hook payloads Claude Code and Codex send. |
| `skill/SKILL.md` | the subagent instructions, linked into `~/.claude/skills` and `~/.agents/skills` (Codex and OpenCode). |
| `install.sh` | state dir, config, Claude Code hooks, Codex hooks plus their trust entries, plugin and skill links. Backs up every file it changes. |
| `path.zsh` | puts `bin/` on PATH. |
| `autoresume.zsh` | sourced by zshrc: an interactive shell in a block that has an active agent record execs `rex-agent`. This is what resumes agents after a restart. |
| `test/restart-test.sh` | end-to-end restart test on a throwaway Rex server, one agent per installed CLI. |

## Where state lives

One JSON file per agent in `~/.local/state/rex-agents/agents/<block-uuid>.json`, written with
a temp file and rename. Each file holds the block ID, name, agent kind, session ID, transcript
path, cwd, model, extra CLI args, env, status, counters, last activity, parent ID and depth.
Limits and the default agent live in `~/.config/rex-agents/config.json` (`max_depth`,
`max_children`, `default_agent`).

Per-file atomic writes mean the hooks, which fire as separate processes, never need a lock,
and `cat` or `jq` read the store directly. It is not inside Rex's own Application Support
directory because the closed-source server owns and rewrites that tree.

## How each agent reports its session

All three agents feed the same consumer, `rex-agents hook`, with the same JSON shape
(`hook_event_name`, `session_id`, `cwd`, `model`, `transcript_path`...). The hook is a no-op
unless `REX_BLOCK` is set.

| agent | wiring | resume command | session store |
|---|---|---|---|
| Claude Code | hooks in `~/.claude/settings.json`: SessionStart, UserPromptSubmit, Stop, Notification, SessionEnd, PostToolUse | `claude --resume <id> [msg]` | `~/.claude/projects/<cwd>/<id>.jsonl` |
| Codex | same hook format in `~/.codex/hooks.json`: SessionStart, UserPromptSubmit, Stop, Interrupt, PermissionRequest, SessionEnd, PostToolUse. Codex runs only hooks it has recorded trust for, so `install.sh` writes `hooks.state` entries for them into `~/.codex/config.toml` (same sha256 identity codex computes). | `codex resume <id> [msg]` | `~/.codex/sessions/YYYY/MM/DD/rollout-*-<id>.jsonl` |
| OpenCode | plugin `opencode/rex-agents.js`, loaded from `~/.config/opencode/plugins`. Maps `session.created`, `chat.message`, `session.idle`, `permission.asked`/`question.asked` and process signals onto the same events; it fetches the last assistant message itself. | `opencode --session <id> [--prompt msg]` | sqlite `~/.local/share/opencode/opencode.db` (table `session`) |

Codex is not on PATH on this machine; the launcher falls back to the copy inside
`/Applications/ChatGPT.app`.

## How a session is captured and resumed

1. `rex-agents spawn [--agent codex|opencode]` opens a tab with
   `rex window new ... -- rex-agent --agent A --name N --prompt P`.
2. `rex-agent` records the block, agent, cwd, args and env, then execs the agent CLI.
3. The agent's hooks keep the record current: SessionStart writes the session ID and
   transcript path, UserPromptSubmit marks `running`, Stop (or Codex's Interrupt) marks `idle`
   and stores the last answer, a permission request marks `blocked`, PostToolUse clears
   `blocked` back to `running` (its shell guard only runs the python while the record says
   blocked), SessionEnd marks `ended`.
4. When Rex dies, each agent gets SIGHUP and its SessionEnd fires with reason `other`. No Rex
   server answers on `REX_SERVER`, so the record becomes `interrupted` and remembers the status
   it had (`running` means mid-turn). A closed tab also gives `other`, but the server still
   answers, so that record becomes `ended`. A clean `/exit` gives reason `exit` and `ended`.
5. Rex restarts and restores the block as a login shell. `autoresume.zsh` sees `REX_BLOCK`,
   finds an active record, and execs `rex-agent`. The launcher checks the session still exists
   (transcript file, or the OpenCode sqlite row), `cd`s to the recorded cwd, re-exports the
   recorded env and runs the agent's resume command. If the agent was mid-turn, the first
   prompt is "rex restarted; continue where you left off". If the session is missing the
   record is marked `broken` and the tab stays a shell with the reason printed. A relaunch less
   than 30 seconds after a launch that never reached SessionStart is refused, so a crashing
   agent cannot loop.

Nothing needs flushing on SIGTERM: every state write happens inside a hook as it occurs, and
the agent is the block's direct child, so Rex's shutdown signals reach it unchanged.

## Checking after a restart

```
rex-agents list              # AGENT column; TAB column: open = block exists, gone = needs restore
rex-agents status <name>     # record plus last assistant message
rex-agents restore --dry-run # agents whose tab vanished and would be reopened
```

## Subagents from any agent

Inside any rex tab, the agent can run:

```
rex-agents spawn --name lint-fix --prompt "..."                   # parent = $REX_BLOCK, tab "↳ parent / lint-fix"
rex-agents spawn --name lint-fix --agent codex --prompt "..."     # or --agent opencode
rex-agents status lint-fix
rex-agents send lint-fix "also check the tests"
rex-agents result lint-fix --timeout 600
```

Depth is capped at `max_depth` (default 2) and running children per parent at
`max_children` (default 5). Subagents use the same launcher, so they also survive restarts.
`skill/SKILL.md` tells each agent when and how to do this; `~/.claude/CLAUDE.md` carries the
same rule for Claude.

## Adopting a session from another tool (herdr)

```
rex-agents spawn --no-parent --name second-brain-audit \
  --cwd "/path/that/started/the/session" --session <session-id> [--agent codex|opencode]
```

Stop the other tool's copy first. Two processes on one session ID would both write the same
transcript file.

## Test

```
rex/test/restart-test.sh          # ~8 minutes; one agent per installed CLI, SIGKILLs the server, checks recall
rex/test/restart-test.sh --keep   # leave the throwaway server up for inspection
```

Codex runs against a throwaway `CODEX_HOME` (auth copied in, hooks trusted there, deleted at the
end). OpenCode runs with its real config and model `OPENCODE_TEST_MODEL` (default
`anthropic/claude-haiku-5-5`); its test session is deleted at the end. Claude's test transcripts
are removed at the end.
