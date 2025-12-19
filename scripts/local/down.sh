#!/bin/bash
#
# down.sh: Stop EchoFinder and tear down the k3d cluster
#
# Usage: ./scripts/local/down.sh
#

set -euo pipefail

CLUSTER_NAME="echofinder"

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

main() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Stopping EchoFinder${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""

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