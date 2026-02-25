#!/usr/bin/env bash
set -e

REPO="https://raw.githubusercontent.com/BrandonMathis/ralph-loop/main"

echo "Downloading start_agent_loop.sh..."
curl -fsSL "$REPO/start_agent_loop.sh" -o start_agent_loop.sh
chmod +x start_agent_loop.sh

echo "Downloading Prompt.md..."
curl -fsSL "$REPO/Prompt.md" -o Prompt.md

echo "Done. Edit Prompt.md with your tasks, then run: ./start_agent_loop.sh"
