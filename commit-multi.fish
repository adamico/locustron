#!/usr/bin/env fish
# Multiline commit helper for fish shell with Conventional Commits support
# Usage: ./commit-multi.fish [commit-args...]

set -l commit_args $argv

# Create a temporary file for the commit message
set -l temp_file (mktemp)

# Function to cleanup temp file on exit
function cleanup --on-signal SIGINT --on-signal SIGTERM
    rm -f $temp_file
    exit 1
end

echo "Conventional Commits format: <type>[optional scope]: <description>"
echo "Valid types: feat, fix, docs, style, refactor, perf, test, chore, ci, revert"
echo ""
echo "Enter commit message (press Ctrl+D on empty line to finish):"
echo "Example: docs(phase-4): add debugging visualization"
echo ""

# Read multiline input
cat > $temp_file

# Check if message is empty
if test -z (cat $temp_file | string trim)
    echo "❌ Error: Commit message cannot be empty"
    rm -f $temp_file
    exit 1
end

# Validate Conventional Commits format
set -l first_line (cat $temp_file | head -1)
set -l pattern '^(feat|fix|docs|style|refactor|perf|test|chore|ci|revert)(\(.+\))?: .+'

if not echo $first_line | grep -qE $pattern
    echo "❌ Error: First line must follow Conventional Commits format:"
    echo "   <type>[optional scope]: <description>"
    echo ""
    echo "Your first line: '$first_line'"
    rm -f $temp_file
    exit 1
end

# Commit with the message file
echo "✅ Committing with message:"
echo "─────────────────────────"
cat $temp_file
echo "─────────────────────────"
echo ""

git commit -F $temp_file $commit_args

# Cleanup
rm -f $temp_file