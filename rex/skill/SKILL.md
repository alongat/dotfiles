---
name: rex-agents
description: Start, watch and message coding-agent subagents that run as Rex tabs (Claude Code, Codex or OpenCode) with the rex-agents CLI. Use when the user asks for a subagent, a background agent, or to "use rex to start" an agent while REX_BLOCK is set.
---

# rex-agents: subagents as Rex tabs

When the user asks for a subagent while you run inside a Rex tab (`REX_BLOCK` is set), start it
with the `rex-agents` CLI instead of a built-in subagent tool. Each subagent is a real tab that
survives a Rex restart, and its tab is titled `↳ <your name> / <sub name>`.

```sh
rex-agents spawn --name <short-name> --prompt "<self-contained prompt>"
rex-agents spawn --name <short-name> --agent codex --prompt "..."      # or --agent opencode
rex-agents status <short-name>                 # running / waiting / done / error + last message
rex-agents result <short-name> --timeout 600   # block until its turn ends, print its answer
rex-agents send <short-name> "<follow-up>"     # type into its tab
rex-agents list                                # every tracked agent
```

Rules:
- Give it a short, descriptive name and a prompt that needs no context from this conversation.
- Poll `status` or block on `result` before continuing. `result` exits 4 and says so when the
  agent is waiting on a permission prompt; tell the user which tab to look at.
- Nesting is capped at 2 levels and at 5 running subagents per parent (see
  `~/.config/rex-agents/config.json`). A refused spawn prints why.
- Do not start a subagent for work you can finish in a few tool calls yourself.
