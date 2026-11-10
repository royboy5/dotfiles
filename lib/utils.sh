#!/usr/bin/env bash
# Logging and the dry-run wrapper shared by ./bootstrap and lib/.

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# execute <cmd> [args...]: run it, or with DRY_RUN=1 only print it.
execute() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo -e "${YELLOW}[DRY] Would run: $*${NC}"
        return 0
    fi
    "$@"
}
