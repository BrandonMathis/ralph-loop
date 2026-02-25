#!/usr/bin/env bash

PROMPT_FILE="Prompt.md"
STATUS_FILE="/tmp/AGENT_STATUS"
TASK_FILE="/tmp/AGENT_TASK"

rm -f "$STATUS_FILE" "$TASK_FILE"

is_done() {
  [[ -f "$1" ]] && [[ "$(cat "$1")" == "done" ]]
}

stop() {
  echo "$1"
  kill "$AGENT_PID" 2>/dev/null
  kill "$WATCHER_PID" 2>/dev/null
  wait "$AGENT_PID" 2>/dev/null
  wait "$WATCHER_PID" 2>/dev/null
  exit "${2:-0}"
}

trap 'stop "⚠️  Interrupted. Stopping loop." 1' INT TERM

while true; do
  is_done "$STATUS_FILE" && { echo "✅ AGENT_STATUS is 'done'. Stopping loop."; break; }

  [[ ! -f "$PROMPT_FILE" ]] && { echo "❌ Error: $PROMPT_FILE not found. Exiting."; exit 1; }

  rm -f "$STATUS_FILE"
  echo "🔄 Running agent loop iteration..."

  # Template-expand the prompt, replacing ${STATUS_FILE}, ${TASK_FILE}, etc.
  EXPANDED_PROMPT=$(sed \
    -e "s|\${STATUS_FILE}|${STATUS_FILE}|g" \
    -e "s|\${TASK_FILE}|${TASK_FILE}|g" \
    "$PROMPT_FILE")

  claude --dangerously-skip-permissions <<< "$EXPANDED_PROMPT" &
  AGENT_PID=$!

  # Watcher: kill agent when a task or status file signals done
  (
    while kill -0 "$AGENT_PID" 2>/dev/null; do
      if is_done "$TASK_FILE"; then
        echo "📋 AGENT_TASK is 'done'. Killing agent (PID $AGENT_PID)."
        rm -f "$TASK_FILE"
        kill "$AGENT_PID" 2>/dev/null
        break
      fi
      if is_done "$STATUS_FILE"; then
        echo "✅ AGENT_STATUS is 'done'. Killing agent (PID $AGENT_PID)."
        kill "$AGENT_PID" 2>/dev/null
        break
      fi
      sleep 0.5
    done
  ) &
  WATCHER_PID=$!

  wait "$AGENT_PID"
  AGENT_EXIT=$?

  [[ $AGENT_EXIT -eq 0 ]] && stop "🏁 Agent exited cleanly. Stopping loop." 0

  is_done "$STATUS_FILE" && { echo "✅ AGENT_STATUS is 'done'. Stopping loop."; break; }
done
