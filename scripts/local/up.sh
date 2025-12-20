#!/bin/bash
#
# up.sh: Start EchoFinder locally on k3d
#
# This script creates a local Kubernetes cluster, builds and deploys
# EchoFinder, and runs smoke tests to verify everything is working.
#
# Usage: ./scripts/local/up.sh
#
# Prerequisites:
#   - Docker Desktop running
#   - k3d installed (brew install k3d)
#   - kubectl installed (brew install kubectl)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLUSTER_NAME="echofinder"
NAMESPACE="echofinder-local"
MAX_WAIT_SECONDS=120
POLL_INTERVAL=5

# Ports for port-forwarding
BACKEND_PORT=8080
FRONTEND_PORT=5173
POSTGRES_PORT=5433  # Use 5433 to avoid conflict with local Postgres on 5432

# Ports for smoke tests (different to avoid conflicts)
SMOKE_BACKEND_PORT=18080
SMOKE_FRONTEND_PORT=18081

# PID file for tracking port-forwards
PID_FILE="$SCRIPT_DIR/.port-forward-pids"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Docker
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    log_success "Docker is running"

    # Check k3d
    if ! command -v k3d >/dev/null 2>&1; then
        log_error "k3d is not installed. Install with: brew install k3d"
        exit 1
    fi
    log_success "k3d is installed ($(k3d version | head -n1))"

    # Check kubectl
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl is not installed. Install with: brew install kubectl"
        exit 1
    fi
    log_success "kubectl is installed"
}

create_cluster() {
    log_info "Setting up k3d cluster: $CLUSTER_NAME"

    if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        log_warn "Cluster '$CLUSTER_NAME' already exists, reusing it"
    else
        log_info "Creating new cluster..."
        k3d cluster create "$CLUSTER_NAME" --wait
        log_success "Cluster created"
    fi

    # Ensure kubectl context is set
    kubectl config use-context "k3d-$CLUSTER_NAME" >/dev/null 2>&1 || true
    log_success "kubectl context set to k3d-$CLUSTER_NAME"
}

build_images() {
    log_info "Building Docker images..."

    cd "$REPO_ROOT"

    log_info "Building backend image..."
    docker build -t echofinder-backend:local ./backend -q
    log_success "Backend image built"

    log_info "Building frontend image..."
    docker build -t echofinder-frontend:local ./frontend -q
    log_success "Frontend image built"
}

import_images() {
    log_info "Importing images into k3d cluster..."

    k3d image import echofinder-backend:local echofinder-frontend:local -c "$CLUSTER_NAME"
    log_success "Images imported"
}

apply_manifests() {
    log_info "Applying Kubernetes manifests..."

    cd "$REPO_ROOT"
    kubectl apply -k k8s/overlays/local
    log_success "Manifests applied to namespace: $NAMESPACE"
}

wait_for_pods() {
    log_info "Waiting for pods to be ready (timeout: ${MAX_WAIT_SECONDS}s)..."

    local start_time=$(date +%s)

    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $MAX_WAIT_SECONDS ]; then
            log_error "Timeout waiting for pods after ${MAX_WAIT_SECONDS}s"
            kubectl get pods -n "$NAMESPACE" -o wide
            exit 1
        fi

        # Check if all pods are fully ready
        local total_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        local ready_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '$2 ~ /^[0-9]+\/[0-9]+$/ { split($2, a, "/"); if (a[1] == a[2] && a[1] > 0) print }' | wc -l | tr -d ' ')

        if [ "$total_pods" -ge 3 ] && [ "$ready_pods" -eq "$total_pods" ]; then
            log_success "All pods ready ($ready_pods/$total_pods)"
            return 0
        fi

        echo -ne "\r  Waiting... (${elapsed}s elapsed, $ready_pods/$total_pods ready)    "
        sleep $POLL_INTERVAL
    done
}

kill_existing_port_forwards() {
    if [ -f "$PID_FILE" ]; then
        log_info "Stopping existing port-forwards..."
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
}

run_smoke_tests() {
    log_info "Running smoke tests..."

    local pids=()

    # Start temporary port-forwards for smoke tests
    kubectl port-forward -n "$NAMESPACE" svc/backend "$SMOKE_BACKEND_PORT:8080" >/dev/null 2>&1 &
    pids+=($!)
    kubectl port-forward -n "$NAMESPACE" svc/frontend "$SMOKE_FRONTEND_PORT:80" >/dev/null 2>&1 &
    pids+=($!)

    # Wait for port-forwards to be ready
    sleep 3

    local test_failed=0

    # Test backend
    log_info "Testing backend /api/health..."
    local backend_body=$(curl -s "http://localhost:$SMOKE_BACKEND_PORT/api/health" || echo "")
    local backend_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$SMOKE_BACKEND_PORT/api/health" || echo "000")

    if [ "$backend_code" = "200" ] && echo "$backend_body" | grep -q '"status"'; then
        log_success "Backend health check passed"
    else
        log_error "Backend health check failed (HTTP $backend_code)"
        test_failed=1
    fi

    # Test frontend
    log_info "Testing frontend /..."
    local frontend_body=$(curl -s "http://localhost:$SMOKE_FRONTEND_PORT/" || echo "")
    local frontend_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$SMOKE_FRONTEND_PORT/" || echo "000")

    if [ "$frontend_code" = "200" ] && echo "$frontend_body" | grep -q "EchoFinder"; then
        log_success "Frontend check passed"
    else
        log_error "Frontend check failed (HTTP $frontend_code)"
        test_failed=1
    fi

    # Clean up smoke test port-forwards
    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null || true
    done

    if [ $test_failed -eq 1 ]; then
        log_error "Smoke tests failed"
        exit 1
    fi

    log_success "All smoke tests passed"
}

start_port_forwards() {
    log_info "Starting port-forwards..."

    # Kill any existing port-forwards first
    kill_existing_port_forwards

    # Start backend port-forward
    kubectl port-forward -n "$NAMESPACE" svc/backend "$BACKEND_PORT:8080" >/dev/null 2>&1 &
    local backend_pid=$!
    echo "$backend_pid" > "$PID_FILE"

    # Start frontend port-forward
    kubectl port-forward -n "$NAMESPACE" svc/frontend "$FRONTEND_PORT:80" >/dev/null 2>&1 &
    local frontend_pid=$!
    echo "$frontend_pid" >> "$PID_FILE"

    # Start postgres port-forward
    kubectl port-forward -n "$NAMESPACE" svc/postgres "$POSTGRES_PORT:5432" >/dev/null 2>&1 &
    local postgres_pid=$!
    echo "$postgres_pid" >> "$PID_FILE"

    # Wait a moment and verify they're running
    sleep 2

    if kill -0 "$backend_pid" 2>/dev/null && kill -0 "$frontend_pid" 2>/dev/null && kill -0 "$postgres_pid" 2>/dev/null; then
        log_success "Port-forwards started (PIDs: $backend_pid, $frontend_pid, $postgres_pid)"
    else
        log_error "Failed to start port-forwards"
        exit 1
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  EchoFinder is running on k3d!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${BLUE}Services:${NC}"
    echo "  Backend:  http://localhost:$BACKEND_PORT/api/health"
    echo "  Frontend: http://localhost:$FRONTEND_PORT"
    echo ""
    echo -e "${BLUE}Database:${NC}"
    echo "  Host:     localhost:$POSTGRES_PORT"
    echo "  Database: echofinder"
    echo "  User:     echofinder"
    echo "  Password: echofinder"
    echo ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  View pods:     kubectl get pods -n $NAMESPACE"
    echo "  View logs:     kubectl logs -n $NAMESPACE -l app=echofinder --all-containers -f"
    echo "  Connect DB:    psql -h localhost -p $POSTGRES_PORT -U echofinder -d echofinder"
    echo "  Stop cluster:  ./scripts/local/down.sh"
    echo ""
}

main() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Starting EchoFinder on k3d${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""

    cd "$REPO_ROOT"

    check_prerequisites
    echo ""

    create_cluster
    echo ""

    build_images
    echo ""

    import_images
    echo ""

    apply_manifests
    echo ""

    wait_for_pods
    echo ""

    run_smoke_tests
    echo ""

    start_port_forwards
    echo ""

    print_summary
}

main "$@"
