#!/bin/bash
# End-to-end restart test for rex-agents.
#
# Starts a throwaway Rex server on its own socket and state dir (the live server is untouched),
# spawns two agents that each memorise a word, kills the server with SIGKILL, starts it again,
# and checks that both agents came back on the same session ids and still know their words.
# One agent is marked mid-turn before the kill to check the "rex restarted" message path.
#
# Needs: rex on PATH, claude on PATH, the rex-agents hooks installed (rex/install.sh).
# Usage: rex/test/restart-test.sh [--keep]   (--keep leaves the test server running)
set -u

KEEP=false
[ "${1:-}" = "--keep" ] && KEEP=true

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HERE/../bin"
WORK="${REX_AGENTS_TEST_DIR:-${TMPDIR:-/tmp}/rex-agents-test-$$}"
mkdir -p "$WORK"
# Unix socket paths are capped at 104 bytes, so the socket gets a short dir of its own.
SOCK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rxa.XXXXXX")"
SOCK="unix://$SOCK_DIR/rex.sock"
export REX_AGENTS_STATE_DIR="$WORK/state"
export REX_SERVER="$SOCK"
unset REX_SESSION REX_BLOCK
# Agents start in the dotfiles repo: it is already trusted, so claude asks no trust question.
AGENT_CWD="$(cd "$HERE/../.." && pwd)"
RA="$BIN/rex-agents"
WORD_A="PELICAN" WORD_B="FLAMINGO"
fails=0
server_pid=""

say()  { echo "› $*"; }
ok()   { echo "  ✅ $*"; }
bad()  { echo "  ❌ $*"; fails=$((fails + 1)); }

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
  for id in "${session_ids[@]:-}"; do
    [ -n "$id" ] && rm -f "$HOME/.claude/projects"/*/"$id.jsonl"
  done
  for id in "${block_ids[@]:-}"; do
    [ -n "$id" ] && rm -f "$HOME/.local/state/rex-agents/redirect/$id"
  done
  rm -rf "$WORK" "$SOCK_DIR"
}
block_ids=()
session_ids=()
trap cleanup EXIT

say "Test dir: $WORK"
say "Starting throwaway rex server"
start_server || exit 1
sess=$(rex --autostart=false -S "$SOCK" new rex-agents-test --json | python3 -c 'import sys,json; print(json.load(sys.stdin)["session_id"])')
ok "server up, session $sess"

spawn() {  # spawn NAME WORD -> prints block uuid
  "$RA" spawn --no-parent --name "$1" --cwd "$AGENT_CWD" --rex-session "$sess" --timeout 120 \
    --prompt "Remember the word $2. Reply with exactly: OK" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["id"], d.get("session_id") or "")'
}

say "Spawning two agents"
read -r id_a sid_a <<<"$(spawn alpha "$WORD_A")"
read -r id_b sid_b <<<"$(spawn beta "$WORD_B")"
session_ids=("$sid_a" "$sid_b")
block_ids=("$id_a" "$id_b")
[ -n "$sid_a" ] && ok "alpha $id_a session $sid_a" || bad "alpha got no session id"
[ -n "$sid_b" ] && ok "beta  $id_b session $sid_b" || bad "beta got no session id"

say "Waiting for both agents to answer their first prompt"
for id in "$id_a" "$id_b"; do
  if "$RA" wait "$id" --state done --timeout 180 >/dev/null; then ok "$id done"; else bad "$id did not finish"; fi
done
"$RA" list

say "Marking alpha as mid-turn (simulates a kill while it was working)"
"$RA" mark "$id_a" --status running

say "SIGKILL the rex server (pid $server_pid)"
kill -9 "$server_pid"; wait "$server_pid" 2>/dev/null
sleep 1
say "Starting the server again"
start_server || exit 1
grep -q "restored saved sessions" "$WORK/server.log" && ok "rex restored its snapshot" || bad "no 'restored saved sessions' in server log"

say "Checking the blocks came back with the same ids"
live=$(rex --autostart=false -S "$SOCK" block ls -s "$sess" --json | python3 -c 'import sys,json; print(" ".join(b["block_id"] for b in json.load(sys.stdin)["blocks"]))')
for id in "$id_a" "$id_b"; do
  case "$live" in *"$id"*) ok "block $id replayed" ;; *) bad "block $id missing after restart (live: $live)" ;; esac
done

say "Waiting for the restored shells to relaunch and resume both sessions"
resumed() {  # resumed ID -> 0 once a SessionStart with source=resume was recorded after the restart
  for _ in $(seq 1 180); do
    src=$("$RA" status "$1" --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("session_start_source") or "", d.get("status") or "")')
    case "$src" in "resume idle"|"resume running"|"resume done") return 0 ;; esac
    sleep 1
  done
  return 1
}
for id in "$id_a" "$id_b"; do
  if resumed "$id"; then ok "$id resumed"; else bad "$id did not come back: $("$RA" status "$id" | head -1)"; fi
done
new_sid_a=$("$RA" status "$id_a" --json | python3 -c 'import sys,json; print(json.load(sys.stdin)["session_id"])')
new_sid_b=$("$RA" status "$id_b" --json | python3 -c 'import sys,json; print(json.load(sys.stdin)["session_id"])')
[ "$new_sid_a" = "$sid_a" ] && ok "alpha kept session id" || bad "alpha session id changed: $sid_a -> $new_sid_a"
[ "$new_sid_b" = "$sid_b" ] && ok "beta kept session id" || bad "beta session id changed: $sid_b -> $new_sid_b"

say "Checking alpha received the restart message"
# alpha was mid-turn, so its relaunch submits the restart prompt as a second turn; wait for it.
for _ in $(seq 1 180); do
  "$RA" status "$id_a" --json | python3 -c 'import sys,json; d=json.load(sys.stdin); sys.exit(0 if d["prompt_count"]>=2 and d["stop_count"]>=2 else 1)' && break
  sleep 1
done
ta="$HOME/.claude/projects/$(echo "$AGENT_CWD" | sed 's/[^A-Za-z0-9]/-/g')/$sid_a.jsonl"
if grep -q "rex restarted; continue where you left off" "$ta" 2>/dev/null; then ok "restart message delivered"; else bad "restart message not in $ta"; fi

say "Asking both agents for their word"
for pair in "$id_a:$WORD_A" "$id_b:$WORD_B"; do
  id=${pair%%:*}; word=${pair##*:}
  "$RA" send "$id" --wait "Which word did I ask you to remember? Reply with just the word." >/dev/null
  answer=$("$RA" result "$id" --timeout 180 2>/dev/null || true)
  case "$answer" in *"$word"*) ok "$id recalled $word" ;; *) bad "$id answered: ${answer:-<nothing>}" ;; esac
done

echo
if [ "$fails" -eq 0 ]; then echo "✅ restart test passed"; else echo "❌ restart test: $fails failure(s)"; fi
exit "$fails"
