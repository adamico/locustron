# Multiline Commit Helper

This repository includes a helper script for creating multiline commit messages that follow Conventional Commits format in fish shell.

## Usage

### Option 1: Automatic override (recommended)

```bash
git commit  # Now automatically uses multiline helper!
```

### Option 2: Explicit alias

```bash
git commit-multi
```

### Option 3: Direct script execution

```bash
./commit-multi.fish
```

## Features

- ✅ **Interactive multiline input** - Type your commit message with multiple lines
- ✅ **Conventional Commits validation** - Ensures proper format compliance
- ✅ **Fish shell compatible** - Works reliably in fish shell environment
- ✅ **Automatic cleanup** - Temporary files are cleaned up automatically
- ✅ **Amend support** - Smart handling of `git commit --amend` with current message pre-populated

## Example Usage

```bash
git commit-multi

# Output:
# Conventional Commits format: <type>[optional scope]: <description>
# Valid types: feat, fix, docs, style, refactor, perf, test, chore, ci, revert
#
# Enter commit message (press Ctrl+D on empty line to finish):
# Example: docs(phase-4): add debugging visualization
#
# docs(phase-4): add debugging visualization
#
# - Implement visualization system
# - Add performance profiler
# - Integrate with main demo
# [Ctrl+D]
#
# ✅ Committing with message:
# ─────────────────────────
# docs(phase-4): add debugging visualization
#
# - Implement visualization system
# - Add performance profiler
# - Integrate with main demo
# ─────────────────────────
```

## Installation

The script is already configured in this repository. For other repositories:

1. Copy `commit-multi.fish` to your repository root
2. Make it executable: `chmod +x commit-multi.fish`
3. Add git alias: `git config alias.commit-multi '!./commit-multi.fish'`

## Why This Solution?

Fish shell doesn't handle multiline strings in quotes the same way bash does. This script provides a reliable way to create properly formatted multiline commit messages that pass the repository's commit validation hooks.
