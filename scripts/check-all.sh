#!/bin/bash
#
# check-all.sh: Run all quality checks for the entire project
#
# This is the single command to verify everything is ready to commit/push.
# Run from repo root: ./scripts/check-all.sh
#
# What it checks:
#   Frontend: lint (strict), tests, build
#   Backend:  Spotless format, tests (unit + integration)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend"
BACKEND_DIR="$REPO_ROOT/backend"

FAILED=0

echo "=============================================="
echo "  EchoFinder - Full Project Quality Check"
echo "=============================================="
echo ""

# Frontend checks
if [ -d "$FRONTEND_DIR" ]; then
    echo "=== Frontend ==="
    cd "$FRONTEND_DIR"

    echo "Running lint (strict mode)..."
    if ! pnpm lint --max-warnings 0; then
        echo "FAILED: Frontend lint"
        FAILED=1
    else
        echo "PASSED: Frontend lint"
    fi

    echo "Running tests..."
    if ! pnpm test --run; then
        echo "FAILED: Frontend tests"
        FAILED=1
    else
        echo "PASSED: Frontend tests"
    fi

    echo "Running build..."
    if ! pnpm build; then
        echo "FAILED: Frontend build"
        FAILED=1
    else
        echo "PASSED: Frontend build"
    fi

    cd "$REPO_ROOT"
    echo ""
fi

# Backend checks
if [ -d "$BACKEND_DIR" ]; then
    echo "=== Backend ==="
    cd "$BACKEND_DIR"

    echo "Running Spotless check..."
    if ! ./mvnw -q spotless:check; then
        echo "FAILED: Backend Spotless"
        echo "  Fix with: cd backend && ./mvnw spotless:apply"
        FAILED=1
    else
        echo "PASSED: Backend Spotless"
    fi

    echo "Running tests (unit + integration)..."
    if ! ./mvnw -q verify -Dspotless.check.skip=true; then
        echo "FAILED: Backend tests"
        FAILED=1
    else
        echo "PASSED: Backend tests"
    fi

    cd "$REPO_ROOT"
    echo ""
fi

# Summary
echo "=============================================="
if [ $FAILED -eq 1 ]; then
    echo "  RESULT: FAILED - Fix issues above"
    echo "=============================================="
    exit 1
fi

echo "  RESULT: ALL CHECKS PASSED"
echo "=============================================="
echo ""
echo "You're ready to commit and push!"
exit 0