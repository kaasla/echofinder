#!/bin/bash
#
# down.sh: Stop EchoFinder and tear down the k3d cluster
#
# Usage: ./scripts/local/down.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="echofinder"
PID_FILE="$SCRIPT_DIR/.port-forward-pids"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

kill_port_forwards() {
    if [ -f "$PID_FILE" ]; then
        log_info "Stopping port-forwards..."
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
        log_success "Port-forwards stopped"
    fi
}

main() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Stopping EchoFinder${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""

    # Kill port-forwards first
    kill_port_forwards

    if ! k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        log_info "Cluster '$CLUSTER_NAME' does not exist, nothing to do"
        exit 0
    fi

    log_info "Deleting k3d cluster: $CLUSTER_NAME"
    k3d cluster delete "$CLUSTER_NAME"

    log_success "Cluster deleted"
    echo ""
    echo -e "${GREEN}EchoFinder has been stopped.${NC}"
    echo ""
}

main "$@"