#!/bin/bash
# End-to-end restart test for rex-agents, across Claude Code, Codex and OpenCode.
#
# Starts a throwaway Rex server on its own socket and state dir (the live server is untouched),
# spawns one agent per installed CLI that each memorise a word, kills the server with SIGKILL,
# starts it again, and checks that every agent came back on the same session id and still knows
# its word. The Claude agent is marked mid-turn before the kill to check the "rex restarted" path.
#
# Codex runs with a throwaway CODEX_HOME (auth copied, hooks trusted there), so the real ~/.codex
# is never touched. OpenCode uses its real config (the plugin is passive) and its test session is
# deleted at the end. Claude uses its real settings; its test transcripts are removed at the end.
#
# Needs: rex (or the Rex app), claude, the rex-agents hooks installed (rex/install.sh).
# Codex and OpenCode are tested when present. OPENCODE_TEST_MODEL picks opencode's model
# (default anthropic/claude-haiku-5-5).
# Usage: rex/test/restart-test.sh [--keep]   (--keep leaves the test server running)
set -u

KEEP=false
[ "${1:-}" = "--keep" ] && KEEP=true

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HERE/../bin"
REX_APP_DIR="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
command -v rex >/dev/null 2>&1 || export PATH="$PATH:$REX_APP_DIR"
TMP="${TMPDIR:-/tmp}"; TMP="${TMP%/}"   # no "//" in paths: codex keys its hook trust on the literal CODEX_HOME path
WORK="${REX_AGENTS_TEST_DIR:-$TMP/rex-agents-test-$$}"
mkdir -p "$WORK"
# Unix socket paths are capped at 104 bytes, so the socket gets a short dir of its own.
SOCK_DIR="$(mktemp -d "$TMP/rxa.XXXXXX")"
SOCK="unix://$SOCK_DIR/rex.sock"
export REX_AGENTS_STATE_DIR="$WORK/state"
export REX_SERVER="$SOCK"
unset REX_SESSION REX_BLOCK
# Agents start in the dotfiles repo: it is already trusted, so claude asks no trust question.
AGENT_CWD="$(cd "$HERE/../.." && pwd)"
RA="$BIN/rex-agents"
CODEX_BIN="$(command -v codex 2>/dev/null || echo /Applications/ChatGPT.app/Contents/Resources/codex)"
CXH="$WORK/codex-home"
OPENCODE_MODEL="${OPENCODE_TEST_MODEL:-anthropic/claude-haiku-5-5}"
fails=0
server_pid=""

say()  { echo "› $*"; }
ok()   { echo "  ✅ $*"; }
bad()  { echo "  ❌ $*"; fails=$((fails + 1)); }
jget() { python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(sys.argv[1]) or "")' "$1"; }

agents=(claude)
if [ -x "$CODEX_BIN" ] && [ -f "$HOME/.codex/auth.json" ]; then agents+=(codex); else say "codex not installed or not logged in; skipping it"; fi
if command -v opencode >/dev/null 2>&1; then agents+=(opencode); else say "opencode not installed; skipping it"; fi

start_server() {
  # Same bare environment launchd gives the real server. Running it with this shell's env would
  # leak a parent Claude session's CLAUDE_* variables into the agents.
  env -i HOME="$HOME" USER="$USER" LOGNAME="$USER" SHELL="${SHELL:-/bin/zsh}" TMPDIR="${TMPDIR:-/tmp}" \
      PATH=/usr/bin:/bin:/usr/sbin:/sbin "$(command -v rex)" server run --listen "$SOCK" \
      --state-dir "$WORK/rex-state" --log-format text >>"$WORK/server.log" 2>&1 &
  server_pid=$!
  for _ in $(seq 1 50); do
    [ -S "$SOCK_DIR/rex.sock" ] && rex --autostart=false -S "$SOCK" ls >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  echo "server did not come up; see $WORK/server.log" >&2
  return 1
}

cleanup() {
  if $KEEP; then
    echo "keeping test server: REX_SERVER=$SOCK REX_AGENTS_STATE_DIR=$REX_AGENTS_STATE_DIR"
    return
  fi
  say "Cleaning up"
  rex --autostart=false -S "$SOCK" server stop >/dev/null 2>&1 || true
  [ -n "$server_pid" ] && { sleep 1; kill "$server_pid" 2>/dev/null || true; }
  for id in "${claude_sessions[@]:-}"; do
    [ -n "$id" ] && rm -f "$HOME/.claude/projects"/*/"$id.jsonl"
  done
  for id in "${opencode_sessions[@]:-}"; do
    [ -n "$id" ] && opencode session delete "$id" >/dev/null 2>&1 || true
  done
  for id in "${block_ids[@]:-}"; do
    [ -n "$id" ] && rm -f "$HOME/.local/state/rex-agents/redirect/$id"
  done
  rm -rf "$WORK" "$SOCK_DIR"   # includes the throwaway CODEX_HOME and its copied auth.json
}
block_ids=()
claude_sessions=()
opencode_sessions=()
trap cleanup EXIT

say "Test dir: $WORK (agents: ${agents[*]})"
if [[ " ${agents[*]} " == *" codex "* ]]; then
  say "Preparing a throwaway CODEX_HOME with trusted rex-agents hooks"
  mkdir -p "$CXH"
  cp "$HOME/.codex/auth.json" "$CXH/auth.json" && chmod 600 "$CXH/auth.json"
  printf '[projects."%s"]\ntrust_level = "trusted"\n' "$AGENT_CWD" > "$CXH/config.toml"
  "$RA" install-hooks --agent codex --path "$CXH/hooks.json" >/dev/null
  "$RA" codex-trust --hooks-json "$CXH/hooks.json" --config "$CXH/config.toml" >/dev/null
  ok "codex home ready"
fi

say "Starting throwaway rex server"
start_server || exit 1
sess=$(rex --autostart=false -S "$SOCK" new rex-agents-test --json | jget session_id)
ok "server up, session $sess"

agent_opts() {  # extra spawn options per agent
  case "$1" in
    codex)    echo "--env CODEX_HOME=$CXH" ;;
    opencode) echo "--model $OPENCODE_MODEL" ;;
    *)        echo "" ;;
  esac
}
remember() {  # remember NAME AGENT WORD -> prints "block_uuid session_id"
  # shellcheck disable=SC2046
  "$RA" spawn --no-parent --agent "$2" --name "$1" --cwd "$AGENT_CWD" --rex-session "$sess" --timeout 150 \
    $(agent_opts "$2") --prompt "Remember the word $3. Reply with exactly: OK" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["id"], d.get("session_id") or "")'
}
track_session() {  # track_session AGENT SESSION_ID
  case "$1" in
    claude)   claude_sessions+=("$2") ;;
    opencode) opencode_sessions+=("$2") ;;
  esac
}

say "Spawning one agent per CLI"
declare -a names=() ids=() sids=() words=() kinds=()
i=0
for agent in "${agents[@]}"; do
  case "$agent" in claude) name=alpha word=PELICAN ;; codex) name=beta word=FLAMINGO ;; opencode) name=gamma word=TOUCAN ;; esac
  read -r id sid <<<"$(remember "$name" "$agent" "$word")"
  names[i]=$name; ids[i]=$id; sids[i]=$sid; words[i]=$word; kinds[i]=$agent
  block_ids+=("$id"); track_session "$agent" "$sid"
  [ -n "$sid" ] && ok "$name ($agent) $id session $sid" || bad "$name ($agent) got no session id"
  i=$((i + 1))
done

say "Waiting for every agent to answer its first prompt"
for i in "${!ids[@]}"; do
  if "$RA" wait "${ids[i]}" --state done --timeout 240 >/dev/null; then ok "${names[i]} done"; else bad "${names[i]} did not finish: $("$RA" status "${ids[i]}" | head -1)"; fi
done
"$RA" list

say "Marking alpha as mid-turn (simulates a kill while it was working)"
"$RA" mark "${ids[0]}" --status running

say "SIGKILL the rex server (pid $server_pid)"
kill -9 "$server_pid"; wait "$server_pid" 2>/dev/null
sleep 2
say "Starting the server again"
start_server || exit 1
grep -q "restored saved sessions" "$WORK/server.log" && ok "rex restored its snapshot" || bad "no 'restored saved sessions' in server log"

say "Checking the blocks came back with the same ids"
live=$(rex --autostart=false -S "$SOCK" block ls -s "$sess" --json | python3 -c 'import sys,json; print(" ".join(b["block_id"] for b in json.load(sys.stdin)["blocks"]))')
for i in "${!ids[@]}"; do
  case "$live" in *"${ids[i]}"*) ok "block ${ids[i]} replayed" ;; *) bad "block ${ids[i]} missing after restart (live: $live)" ;; esac
done

say "Waiting for the restored shells to relaunch and resume every session"
resumed() {  # resumed ID -> 0 once a SessionStart with source=resume was recorded after the restart
  for _ in $(seq 1 180); do
    src=$("$RA" status "$1" --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("session_start_source") or "", d.get("status") or "")')
    case "$src" in "resume idle"|"resume running"|"resume done"|"resume blocked") return 0 ;; esac
    sleep 1
  done
  return 1
}
for i in "${!ids[@]}"; do
  if resumed "${ids[i]}"; then ok "${names[i]} (${kinds[i]}) resumed"; else bad "${names[i]} did not come back: $("$RA" status "${ids[i]}" | head -1)"; fi
  new_sid=$("$RA" status "${ids[i]}" --json | jget session_id)
  [ "$new_sid" = "${sids[i]}" ] && ok "${names[i]} kept session id" || bad "${names[i]} session id changed: ${sids[i]} -> $new_sid"
done

say "Checking alpha received the restart message"
# alpha was mid-turn, so its relaunch submits the restart prompt as a second turn; wait for it.
for _ in $(seq 1 180); do
  "$RA" status "${ids[0]}" --json | python3 -c 'import sys,json; d=json.load(sys.stdin); sys.exit(0 if d["prompt_count"]>=2 and d["stop_count"]>=2 else 1)' && break
  sleep 1
done
ta="$HOME/.claude/projects/$(echo "$AGENT_CWD" | sed 's/[^A-Za-z0-9]/-/g')/${sids[0]}.jsonl"
if grep -q "rex restarted; continue where you left off" "$ta" 2>/dev/null; then ok "restart message delivered"; else bad "restart message not in $ta"; fi

say "Asking every agent for its word"
for i in "${!ids[@]}"; do
  "$RA" send "${ids[i]}" --wait "Which word did I ask you to remember? Reply with just the word." >/dev/null
  answer=$("$RA" result "${ids[i]}" --timeout 240 2>/dev/null || true)
  case "$answer" in *"${words[i]}"*) ok "${names[i]} (${kinds[i]}) recalled ${words[i]}" ;; *) bad "${names[i]} answered: ${answer:-<nothing>}" ;; esac
done

say "Subagents: alpha spawns a child, the child spawns a grandchild, depth 3 is refused"
child_agent=claude; child_opts=""
if [[ " ${agents[*]} " == *" codex "* ]]; then child_agent=codex; child_opts="--env CODEX_HOME=$CXH"; fi
# shellcheck disable=SC2086
child_json=$(REX_BLOCK="block:${ids[0]}" REX_SESSION="$sess" "$RA" spawn --name child --agent "$child_agent" $child_opts \
  --cwd "$AGENT_CWD" --timeout 150 --prompt "Reply with exactly: child ready")
id_c=$(echo "$child_json" | jget id)
sid_c=$(echo "$child_json" | jget session_id)
block_ids+=("$id_c"); track_session "$child_agent" "$sid_c"
parent_ok=$("$RA" status "$id_c" --json | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if d["parent_id"]=="'"${ids[0]}"'" and d["depth"]==1 and d["agent"]=="'"$child_agent"'" else d)')
[ "$parent_ok" = "ok" ] && ok "child ($child_agent) records parent alpha, depth 1" || bad "child record wrong: $parent_ok"
label=$(rex --autostart=false -S "$SOCK" window ls -s "$sess" --json | python3 -c 'import sys,json; print([w["label"] for w in json.load(sys.stdin)["windows"] if "child" in w["label"]][0])')
[ "$label" = "↳ alpha / child" ] && ok "tab labelled '$label'" || bad "tab label is '$label'"
"$RA" wait "$id_c" --state done --timeout 240 >/dev/null && ok "child finished" || bad "child did not finish"
case "$("$RA" result "$id_c" --timeout 30)" in *"child ready"*) ok "parent collected the child's result" ;; *) bad "child result missing" ;; esac

grand_json=$(REX_BLOCK="block:$id_c" REX_SESSION="$sess" "$RA" spawn --name grandchild --cwd "$AGENT_CWD" --timeout 150 \
  --prompt "Reply with exactly: OK")
id_g=$(echo "$grand_json" | jget id)
claude_sessions+=("$(echo "$grand_json" | jget session_id)"); block_ids+=("$id_g")
[ -n "$id_g" ] && ok "grandchild spawned at depth 2" || bad "grandchild failed"
if REX_BLOCK="block:$id_g" REX_SESSION="$sess" "$RA" spawn --name toodeep --cwd "$AGENT_CWD" --prompt x 2>"$WORK/deep.err"; then
  bad "depth 3 was allowed"
else
  grep -q "nesting limit" "$WORK/deep.err" && ok "depth 3 refused: $(cat "$WORK/deep.err")" || bad "depth 3 failed for another reason: $(cat "$WORK/deep.err")"
fi
if REX_AGENTS_MAX_CHILDREN=1 REX_BLOCK="block:${ids[0]}" REX_SESSION="$sess" "$RA" spawn --name second --cwd "$AGENT_CWD" --prompt x 2>"$WORK/kids.err"; then
  bad "max_children=1 was not enforced"
else
  grep -q "max_children" "$WORK/kids.err" && ok "max_children enforced" || bad "max_children failed for another reason: $(cat "$WORK/kids.err")"
fi

echo
if [ "$fails" -eq 0 ]; then echo "✅ restart test passed (${agents[*]})"; else echo "❌ restart test: $fails failure(s)"; fi
exit "$fails"
