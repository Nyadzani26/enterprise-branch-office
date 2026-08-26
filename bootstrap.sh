#!/usr/bin/env bash
# ==============================================================================
# Enterprise Branch Office Infrastructure - Automated Bootstrap Script
# ==============================================================================
set -euo pipefail
# Ensure rootless runtime directories exist
export XDG_RUNTIME_DIR="/tmp/containers-run-$(id -u)"
mkdir -p "${XDG_RUNTIME_DIR}" "/tmp/containers-storage-$(id -u)"
chmod 700 "${XDG_RUNTIME_DIR}"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}  ENTERPRISE BRANCH OFFICE INFRASTRUCTURE BOOTSTRAP  ${NC}"
echo -e "${BLUE}================================================================${NC}"
# 1. Container engine detection
run_compose() {
    if command -v docker-compose &>/dev/null; then
        docker-compose "$@"
    elif docker compose version &>/dev/null 2>&1; then
        docker compose "$@"
    elif [[ -f "/opt/ohpc/miniconda3/bin/podman-compose" ]]; then
        /opt/ohpc/miniconda3/bin/python3 /opt/ohpc/miniconda3/bin/podman-compose "$@"
    elif command -v podman-compose &>/dev/null; then
        podman-compose "$@"
    else
        log_error "Neither docker compose nor podman-compose was found!"
        exit 1
    fi
}
log_success "Using container orchestrator: run_compose"
# 2. Check environment configuration
if [[ ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
        cp .env.example .env
        RAND_DB_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
        RAND_ROOT_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
        sed -i "s/ChangeThisStrongWikiPass123!/${RAND_DB_PASS}/g" .env
        sed -i "s/ChangeThisStrongRootPass123!/${RAND_ROOT_PASS}/g" .env
        log_success "Created .env with generated credentials."
    fi
fi
# 3. Create persistent directories
mkdir -p data/mariadb data/gitea data/uptime-kuma data/prometheus data/loki data/grafana
# 4. Pull images sequentially to prevent VFS race conditions
log_info "Pre-pulling container images sequentially..."
IMAGES=(
    "docker.io/library/mariadb:10.11"
    "docker.io/gitea/gitea:1.21"
    "docker.io/requarks/wiki:2"
    "docker.io/louislam/uptime-kuma:1"
    "docker.io/prom/node-exporter:latest"
    "docker.io/prom/prometheus:latest"
    "docker.io/grafana/loki:latest"
    "docker.io/grafana/promtail:latest"
    "docker.io/grafana/grafana:latest"
    "docker.io/library/nginx:alpine"
)
for img in "${IMAGES[@]}"; do
    echo -e "  --> Pulling ${img}..."
    podman pull "${img}" >/dev/null 2>&1 || true
done
log_success "All container images verified in local storage."
# 5. Launch stack
log_info "Starting containerized branch services..."
run_compose up -d
log_success "All branch containers launched."
