#!/usr/bin/env bash

PROMPT_FILE="Prompt.md"
STATUS_FILE="/tmp/CLAUDE_STATUS"
TASK_FILE="/tmp/CLAUDE_TASK"

rm -f "$STATUS_FILE" "$TASK_FILE"

while true; do
  # Check for stop condition before running
  if [[ -f "$STATUS_FILE" ]] && [[ "$(cat "$STATUS_FILE")" == "done" ]]; then
    echo "CLAUDE_STATUS is 'done'. Stopping loop."
    break
  fi

  if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: $PROMPT_FILE not found. Exiting."
    exit 1
  fi

  rm -f "$STATUS_FILE"
  echo "--- Running claude loop iteration ---"

  # Template-expand the prompt, replacing ${STATUS_FILE}, ${TASK_FILE}, etc.
  EXPANDED_PROMPT=$(STATUS_FILE="$STATUS_FILE" TASK_FILE="$TASK_FILE" envsubst < "$PROMPT_FILE")

  # Run claude in background to capture PID
  claude --dangerously-skip-permissions <<< "$EXPANDED_PROMPT" &
  CLAUDE_PID=$!

  # Start watcher sub-loop in background
  (
    while kill -0 "$CLAUDE_PID" 2>/dev/null; do
      if [[ -f "$TASK_FILE" ]] && [[ "$(cat "$TASK_FILE")" == "done" ]]; then
        echo "CLAUDE_TASK is 'done'. Killing claude (PID $CLAUDE_PID)."
        rm -f "$TASK_FILE"
        kill "$CLAUDE_PID" 2>/dev/null
        break
      fi
      if [[ -f "$STATUS_FILE" ]] && [[ "$(cat "$STATUS_FILE")" == "done" ]]; then
        echo "CLAUDE_STATUS is 'done'. Killing claude (PID $CLAUDE_PID)."
        kill "$CLAUDE_PID" 2>/dev/null
        break
      fi
      sleep 0.5
    done
  ) &
  WATCHER_PID=$!

  # Wait for claude to finish (naturally or killed by watcher)
  wait "$CLAUDE_PID"

  # Kill watcher if still running
  kill "$WATCHER_PID" 2>/dev/null
  wait "$WATCHER_PID" 2>/dev/null

  # Check for stop condition after running
  if [[ -f "$STATUS_FILE" ]] && [[ "$(cat "$STATUS_FILE")" == "done" ]]; then
    echo "CLAUDE_STATUS is 'done'. Stopping loop."
    break
  fi
done
