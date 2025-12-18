#!/bin/bash
# Installs Git hooks from scripts/git-hooks to .git/hooks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing Git hooks..."
echo "  Source: $SCRIPT_DIR"
echo "  Target: $GIT_HOOKS_DIR"
echo ""

# Ensure .git/hooks directory exists
mkdir -p "$GIT_HOOKS_DIR"

# Install commit-msg hook
if [ -f "$SCRIPT_DIR/commit-msg" ]; then
    cp "$SCRIPT_DIR/commit-msg" "$GIT_HOOKS_DIR/commit-msg"
    chmod +x "$GIT_HOOKS_DIR/commit-msg"
    echo "  Installed: commit-msg"
fi

# Install pre-push hook
if [ -f "$SCRIPT_DIR/pre-push" ]; then
    cp "$SCRIPT_DIR/pre-push" "$GIT_HOOKS_DIR/pre-push"
    chmod +x "$GIT_HOOKS_DIR/pre-push"
    echo "  Installed: pre-push"
fi

echo ""
echo "Git hooks installed successfully."
echo ""
echo "To verify, try an invalid commit message:"
echo "  git commit --allow-empty -m 'bad message'"
echo ""
echo "It should be rejected with an error."