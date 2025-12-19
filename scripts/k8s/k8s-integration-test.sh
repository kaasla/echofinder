#!/bin/bash
#
# k8s-integration-test.sh: Kubernetes integration tests
#
# Creates a k3d cluster, builds and loads images, deploys manifests,
# and validates that services are reachable.
#
# Usage: ./scripts/k8s/k8s-integration-test.sh
#
# Prerequisites:
#   - Docker running
#   - k3d installed
#   - kubectl installed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLUSTER_NAME="echofinder-test"
NAMESPACE="echofinder-local"
MAX_WAIT_SECONDS=120
POLL_INTERVAL=5

# Ports for port-forwarding
BACKEND_LOCAL_PORT=18080
FRONTEND_LOCAL_PORT=18081

# Track background processes for cleanup
PORT_FORWARD_PIDS=()

cleanup() {
    echo ""
    echo "=== Cleaning up ==="

    # Kill port-forward processes
    for pid in "${PORT_FORWARD_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "Killing port-forward process $pid"
            kill "$pid" 2>/dev/null || true
        fi
    done

    # Delete k3d cluster
    if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        echo "Deleting k3d cluster: $CLUSTER_NAME"
        k3d cluster delete "$CLUSTER_NAME" 2>/dev/null || true
    fi

    echo "Cleanup complete"
}

trap cleanup EXIT

wait_for_pods() {
    local namespace=$1
    local timeout=$2
    local start_time=$(date +%s)

    echo "Waiting for all pods in namespace '$namespace' to be Ready..."

    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $timeout ]; then
            echo "ERROR: Timeout waiting for pods to be Ready after ${timeout}s"
            kubectl get pods -n "$namespace" -o wide
            return 1
        fi

        # Check if all pods are fully ready (all containers running)
        # Look for pods where READY column shows all containers ready (e.g., "1/1")
        local total_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local ready_pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | awk '$2 ~ /^[0-9]+\/[0-9]+$/ { split($2, a, "/"); if (a[1] == a[2] && a[1] > 0) print }' | wc -l | tr -d ' ')

        if [ "$total_pods" -ge 2 ] && [ "$ready_pods" -eq "$total_pods" ]; then
            echo "All pods are Ready! ($ready_pods/$total_pods)"
            kubectl get pods -n "$namespace"
            return 0
        fi

        echo "  Waiting... (${elapsed}s elapsed, $ready_pods/$total_pods ready)"
        kubectl get pods -n "$namespace" --no-headers 2>/dev/null || true
        sleep $POLL_INTERVAL
    done
}

start_port_forward() {
    local service=$1
    local local_port=$2
    local target_port=$3
    local namespace=$4

    echo "Starting port-forward: localhost:$local_port -> $service:$target_port"
    kubectl port-forward -n "$namespace" "svc/$service" "$local_port:$target_port" &
    local pid=$!
    PORT_FORWARD_PIDS+=($pid)

    # Wait for port-forward to be ready
    sleep 3

    if ! kill -0 "$pid" 2>/dev/null; then
        echo "ERROR: Port-forward for $service failed to start"
        return 1
    fi

    echo "Port-forward started (PID: $pid)"
}

test_backend() {
    echo ""
    echo "=== Testing Backend ==="

    local url="http://localhost:$BACKEND_LOCAL_PORT/api/health"
    echo "Testing: GET $url"

    # Get body and status separately (works on both macOS and Linux)
    local body=$(curl -s "$url")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    echo "Response code: $http_code"
    echo "Response body: $body"

    if [ "$http_code" != "200" ]; then
        echo "[FAIL] Backend health check failed (HTTP $http_code)"
        return 1
    fi

    if echo "$body" | grep -q '"status"'; then
        echo "[PASS] Response contains 'status' field"
    else
        echo "[FAIL] Response missing 'status' field"
        return 1
    fi

    # Check correlation ID header
    local headers=$(curl -s -I "http://localhost:$BACKEND_LOCAL_PORT/api/health")
    if echo "$headers" | grep -qi "x-correlation-id"; then
        echo "[PASS] X-Correlation-Id header present"
    else
        echo "[FAIL] X-Correlation-Id header missing"
        return 1
    fi

    echo "Backend tests passed!"
}

test_frontend() {
    echo ""
    echo "=== Testing Frontend ==="

    local url="http://localhost:$FRONTEND_LOCAL_PORT/"
    echo "Testing: GET $url"

    # Get body and status separately (works on both macOS and Linux)
    local body=$(curl -s "$url")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    echo "Response code: $http_code"

    if [ "$http_code" != "200" ]; then
        echo "[FAIL] Frontend request failed (HTTP $http_code)"
        return 1
    fi

    if echo "$body" | grep -q "EchoFinder"; then
        echo "[PASS] Response contains 'EchoFinder'"
    else
        echo "[FAIL] Response missing 'EchoFinder' text"
        return 1
    fi

    echo "Frontend tests passed!"
}

echo "=============================================="
echo "  EchoFinder Kubernetes Integration Tests"
echo "=============================================="
echo ""

cd "$REPO_ROOT"

# Step 1: Create k3d cluster
echo "=== Creating k3d cluster: $CLUSTER_NAME ==="
if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    echo "Cluster already exists, deleting..."
    k3d cluster delete "$CLUSTER_NAME"
fi

k3d cluster create "$CLUSTER_NAME" --wait

# Verify kubectl context
kubectl cluster-info
echo ""

# Step 2: Build Docker images
echo "=== Building Docker images ==="
docker build -t echofinder-backend:local ./backend
docker build -t echofinder-frontend:local ./frontend
echo ""

# Step 3: Load images into k3d
echo "=== Loading images into k3d cluster ==="
k3d image import echofinder-backend:local echofinder-frontend:local -c "$CLUSTER_NAME"
echo ""

# Step 4: Apply Kubernetes manifests
echo "=== Applying Kubernetes manifests ==="
kubectl apply -k k8s/overlays/local
echo ""

# Step 5: Wait for pods to be Ready
wait_for_pods "$NAMESPACE" "$MAX_WAIT_SECONDS"
echo ""

# Step 6: Start port-forwards
echo "=== Starting port-forwards ==="
start_port_forward "backend" "$BACKEND_LOCAL_PORT" "8080" "$NAMESPACE"
start_port_forward "frontend" "$FRONTEND_LOCAL_PORT" "80" "$NAMESPACE"
echo ""

# Step 7: Run tests
test_backend
test_frontend

echo ""
echo "=============================================="
echo "  ALL KUBERNETES INTEGRATION TESTS PASSED"
echo "=============================================="