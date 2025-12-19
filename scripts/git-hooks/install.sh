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
    echo "  Installed: commit-msg (Conventional Commits enforcement)"
fi

# Install pre-commit hook
if [ -f "$SCRIPT_DIR/pre-commit" ]; then
    cp "$SCRIPT_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "  Installed: pre-commit (lint strict mode)"
fi

# Install pre-push hook
if [ -f "$SCRIPT_DIR/pre-push" ]; then
    cp "$SCRIPT_DIR/pre-push" "$GIT_HOOKS_DIR/pre-push"
    chmod +x "$GIT_HOOKS_DIR/pre-push"
    echo "  Installed: pre-push (tests + build)"
fi

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "What each hook does:"
echo "  commit-msg  - Blocks commits without Conventional Commits format"
echo "  pre-commit  - Blocks commits with lint errors/warnings or Spotless issues"
echo "  pre-push    - Blocks pushes with failing tests or build errors"
echo ""
echo "To test commit-msg hook:"
echo "  git commit --allow-empty -m 'bad message'  # Should be rejected"
echo "  git commit --allow-empty -m 'feat: test'   # Should succeed"
echo ""
echo "Environment variables:"
echo "  SKIP_HOOKS=1 - Bypass all hooks (emergency only)"
echo ""
echo "To check everything before committing:"
echo "  ./scripts/check-all.sh"