# Agent Loop

A command line utility that runs Claude Code CLI in a loop to work tasks one by one from a Prompt.md

## Project Goals
1. Can be cloned down and run with minimal setup
1. This project can work in existing repos with minimal configuration
1. Zero dependencies other than Claude Code and bash

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BrandonMathis/ralph-loop/main/install.sh)
```

This downloads `start_claude_loop.sh` and `Prompt.md` into your current directory.

## Usage
1. Edit `Prompt.md` with your tasks
2. Run `./start_claude_loop.sh`
