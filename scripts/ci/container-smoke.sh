#!/bin/bash
#
# container-smoke.sh: Container integration tests
#
# Tests that Docker images build and run correctly:
# - Backend image builds and /api/health responds
# - Frontend image builds and serves the SPA
#
# Usage: ./scripts/ci/container-smoke.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BACKEND_PORT=8080
FRONTEND_PORT=5173
MAX_RETRIES=30
RETRY_INTERVAL=2

cleanup() {
    echo ""
    echo "=== Cleaning up containers ==="
    cd "$REPO_ROOT"
    docker compose down -v --remove-orphans 2>/dev/null || true
}

trap cleanup EXIT

wait_for_service() {
    local url=$1
    local name=$2
    local retries=0

    echo "Waiting for $name at $url..."
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
            echo "$name is ready!"
            return 0
        fi
        retries=$((retries + 1))
        echo "  Attempt $retries/$MAX_RETRIES - waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    done

    echo "ERROR: $name failed to become ready after $MAX_RETRIES attempts"
    return 1
}

echo "=============================================="
echo "  EchoFinder Container Smoke Tests"
echo "=============================================="
echo ""

cd "$REPO_ROOT"

# Build and start containers
echo "=== Building and starting containers ==="
docker compose up --build -d

# Test backend
echo ""
echo "=== Testing Backend ==="
wait_for_service "http://localhost:$BACKEND_PORT/api/health" "Backend"

echo "Checking /api/health response..."
HEALTH_RESPONSE=$(curl -s http://localhost:$BACKEND_PORT/api/health)
echo "Response: $HEALTH_RESPONSE"

# Validate response contains required fields
if echo "$HEALTH_RESPONSE" | grep -q '"status"'; then
    echo "  [PASS] Response contains 'status' field"
else
    echo "  [FAIL] Response missing 'status' field"
    exit 1
fi

if echo "$HEALTH_RESPONSE" | grep -q '"service"'; then
    echo "  [PASS] Response contains 'service' field"
else
    echo "  [FAIL] Response missing 'service' field"
    exit 1
fi

# Check for correlation ID header
echo "Checking X-Correlation-Id header..."
CORRELATION_ID=$(curl -s -I http://localhost:$BACKEND_PORT/api/health | grep -i "x-correlation-id" || true)
if [ -n "$CORRELATION_ID" ]; then
    echo "  [PASS] X-Correlation-Id header present: $CORRELATION_ID"
else
    echo "  [FAIL] X-Correlation-Id header missing"
    exit 1
fi

# Test frontend
echo ""
echo "=== Testing Frontend ==="
wait_for_service "http://localhost:$FRONTEND_PORT/" "Frontend"

echo "Checking frontend response..."
FRONTEND_RESPONSE=$(curl -s http://localhost:$FRONTEND_PORT/)

if echo "$FRONTEND_RESPONSE" | grep -q "EchoFinder"; then
    echo "  [PASS] Frontend contains 'EchoFinder'"
else
    echo "  [FAIL] Frontend missing 'EchoFinder' text"
    exit 1
fi

# Test SPA routing (non-existent route should return index.html, not 404)
echo "Checking SPA routing..."
SPA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$FRONTEND_PORT/some/random/route)
if [ "$SPA_STATUS" = "200" ]; then
    echo "  [PASS] SPA routing works (returns 200 for client routes)"
else
    echo "  [FAIL] SPA routing broken (got $SPA_STATUS instead of 200)"
    exit 1
fi

echo ""
echo "=============================================="
echo "  ALL CONTAINER SMOKE TESTS PASSED"
echo "=============================================="