#!/usr/bin/env bash

PROMPT_FILE="Prompt.md"
STATUS_FILE="/tmp/CLAUDE_STATUS"
TASK_FILE="/tmp/CLAUDE_TASK"

rm -f "$STATUS_FILE" "$TASK_FILE"

is_done() {
  [[ -f "$1" ]] && [[ "$(cat "$1")" == "done" ]]
}

stop() {
  echo "$1"
  kill "$CLAUDE_PID" 2>/dev/null
  kill "$WATCHER_PID" 2>/dev/null
  wait "$CLAUDE_PID" 2>/dev/null
  wait "$WATCHER_PID" 2>/dev/null
  exit "${2:-0}"
}

trap 'stop "⚠️  Interrupted. Stopping loop." 1' INT TERM

while true; do
  is_done "$STATUS_FILE" && { echo "✅ CLAUDE_STATUS is 'done'. Stopping loop."; break; }

  [[ ! -f "$PROMPT_FILE" ]] && { echo "❌ Error: $PROMPT_FILE not found. Exiting."; exit 1; }

  rm -f "$STATUS_FILE"
  echo "🔄 Running claude loop iteration..."

  # Template-expand the prompt, replacing ${STATUS_FILE}, ${TASK_FILE}, etc.
  EXPANDED_PROMPT=$(sed \
    -e "s|\${STATUS_FILE}|${STATUS_FILE}|g" \
    -e "s|\${TASK_FILE}|${TASK_FILE}|g" \
    "$PROMPT_FILE")

  claude --dangerously-skip-permissions <<< "$EXPANDED_PROMPT" &
  CLAUDE_PID=$!

  # Watcher: kill claude when a task or status file signals done
  (
    while kill -0 "$CLAUDE_PID" 2>/dev/null; do
      if is_done "$TASK_FILE"; then
        echo "📋 CLAUDE_TASK is 'done'. Killing claude (PID $CLAUDE_PID)."
        rm -f "$TASK_FILE"
        kill "$CLAUDE_PID" 2>/dev/null
        break
      fi
      if is_done "$STATUS_FILE"; then
        echo "✅ CLAUDE_STATUS is 'done'. Killing claude (PID $CLAUDE_PID)."
        kill "$CLAUDE_PID" 2>/dev/null
        break
      fi
      sleep 0.5
    done
  ) &
  WATCHER_PID=$!

  wait "$CLAUDE_PID"
  CLAUDE_EXIT=$?

  [[ $CLAUDE_EXIT -eq 0 ]] && stop "🏁 Claude exited cleanly. Stopping loop." 0

  is_done "$STATUS_FILE" && { echo "✅ CLAUDE_STATUS is 'done'. Stopping loop."; break; }
done
