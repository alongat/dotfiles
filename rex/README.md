# rex-agents

Claude Code agents that run in Rex tabs and survive a Rex server restart, plus a CLI for
starting subagents as Rex tabs instead of the built-in Task tool.

Rex is superlogical's closed-source multiplexer. It already snapshots every session, window
and block, and brings each block back with the same block ID and cwd when the server
restarts. It does not replay the block's command (the server log says
`not replaying creation options on restore dropped=[command]`), so a restored agent tab is a
plain login shell with `REX_BLOCK` set. These scripts turn that shell back into the agent
without touching Rex itself.

## Pieces

| file | role |
|---|---|
| `bin/rex-agent` | block command. Looks up its own block in the state store and runs `claude`, `claude --resume <id>`, or marks the record broken and leaves a shell. |
| `bin/rex-agents` | CLI and hook consumer: `list`, `status`, `spawn`, `send`, `result`, `wait`, `restore`, `rm`. |
| `install.sh` | creates the state dir and config, installs the Claude Code hooks (backs up `~/.claude/settings.json` first). |
| `path.zsh` | puts `bin/` on PATH. |
| `autoresume.zsh` | sourced by zshrc: an interactive shell in a block that has an active agent record execs `rex-agent`. This is what resumes agents after a restart. |
| `test/restart-test.sh` | end-to-end restart test on a throwaway Rex server. |

## Where state lives

One JSON file per agent in `~/.local/state/rex-agents/agents/<block-uuid>.json`, written with
a temp file and rename. Each file holds the block ID, name, Claude session ID, transcript path,
cwd, model, extra claude args, status, counters, last activity, parent ID and depth.
Limits live in `~/.config/rex-agents/config.json` (`max_depth`, `max_children`).

Per-file atomic writes mean the hooks, which fire as separate processes, never need a lock,
and `cat` or `jq` read the store directly. It is not inside Rex's own Application Support
directory because the closed-source server owns and rewrites that tree.

## How a session is captured and resumed

1. `rex-agents spawn` opens a tab with `rex window new ... -- rex-agent --name N --prompt P`.
2. `rex-agent` records the block, cwd and args, then execs `claude`.
3. Claude Code hooks (installed in `~/.claude/settings.json`, no-ops unless `REX_BLOCK` is set)
   keep the record current: SessionStart writes the session ID and transcript path,
   UserPromptSubmit marks `running`, Stop marks `idle`, a permission Notification marks
   `blocked`, SessionEnd marks `ended`.
4. When Rex dies, each `claude` gets SIGHUP and its SessionEnd hook fires with reason
   `other`. The record becomes `interrupted` and remembers the status it had (`running`
   means mid-turn). A clean `/exit` gives reason `exit` and the record becomes `ended`.
5. Rex restarts and restores the block as a login shell. `autoresume.zsh` sees `REX_BLOCK`,
   finds an active record, and execs `rex-agent`. The launcher checks the transcript file
   exists, `cd`s to the recorded cwd and runs `claude --resume <id>`. If the agent was
   mid-turn, the first prompt is "rex restarted; continue where you left off". If the
   transcript is missing the record is marked `broken` and the tab stays a shell with the
   reason printed. A relaunch less than 30 seconds after the previous one is refused, so a
   crashing agent cannot loop.

Nothing needs flushing on SIGTERM: every state write happens inside a hook as it occurs, and
`claude` is the block's direct child, so Rex's shutdown signals reach it unchanged.

## Checking after a restart

```
rex-agents list              # TAB column: open = block exists, gone = needs restore
rex-agents status <name>     # record plus last assistant message
rex-agents restore --dry-run # agents whose tab vanished and would be reopened
```

## Subagents from Claude Code

Inside any rex tab, Claude can run:

```
rex-agents spawn --name lint-fix --prompt "..."      # parent = $REX_BLOCK, tab "↳ parent / lint-fix"
rex-agents status lint-fix
rex-agents send lint-fix "also check the tests"
rex-agents result lint-fix --timeout 600
```

Depth is capped at `max_depth` (default 2) and running children per parent at
`max_children` (default 5). Subagents use the same launcher, so they also survive restarts.

## Adopting a session from another tool (herdr)

```
rex-agents spawn --no-parent --name second-brain-audit \
  --cwd "/path/that/started/the/session" --session <claude-session-id>
```

Stop the other tool's copy first. Two processes on one session ID would both write the same
transcript file.

## Test

```
rex/test/restart-test.sh          # ~5 minutes; spawns two agents, SIGKILLs the server, checks recall
rex/test/restart-test.sh --keep   # leave the throwaway server up for inspection
```
