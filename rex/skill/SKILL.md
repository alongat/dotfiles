---
name: rex-agents
description: Start, watch and message coding-agent subagents that run as Rex tabs (Claude Code, Codex or OpenCode) with the rex-agents CLI. Use whenever REX_BLOCK is set and a subagent would help, whether the user asked for one or you decided to delegate (parallel work, a side task, a wide search). Replaces the built-in Agent tool inside Rex.
---

# rex-agents: subagents as Rex tabs

Inside a Rex tab (`REX_BLOCK` is set), start every subagent with the `rex-agents` CLI instead of
the built-in Agent tool. That includes the ones you decide on yourself, not only the ones the user
asks for. Each subagent is a real tab the user can watch, it survives a Rex restart, and its tab
is titled `↳ <your name> / <sub name>`.

Delegate when the work splits into independent parts, when a side task shouldn't block the main
thread, or when answering means reading across many files. Run independent subagents in parallel
and collect each with `result`.

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
