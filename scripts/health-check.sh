#!/usr/bin/env bash
set -uo pipefail
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"
echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   ENTERPRISE BRANCH OFFICE - SYSTEM HEALTH CHECK   ${NC}"
echo -e "${BLUE}====================================================${NC}"
CONTAINERS=(
    "branch-mariadb"
    "branch-gitea"
    "branch-wikijs"
    "branch-uptime-kuma"
    "branch-node-exporter"
    "branch-prometheus"
    "branch-loki"
    "branch-promtail"
    "branch-grafana"
    "branch-nginx"
)
echo -e "${BLUE}[1/2] Probing Container States...${NC}"
for c in "${CONTAINERS[@]}"; do
    if podman inspect -f '{{.State.Running}}' "$c" 2>/dev/null | grep -q "true" ||        docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null | grep -q "true"; then
        echo -e "  [+] Container: $c  --> ${GREEN}[RUNNING]${NC}"
    else
        echo -e "  [-] Container: $c  --> ${RED}[DOWN / STOPPED]${NC}"
    fi
done
echo ""
echo -e "${BLUE}[2/2] Testing Ingress HTTP Endpoints (Port 8080)...${NC}"
ENDPOINTS=(
    "/"
    "/git/"
    "/wiki/"
    "/grafana/"
)
for ep in "${ENDPOINTS[@]}"; do
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8080${ep}" 2>/dev/null || echo "000")
    if [[ "$STATUS_CODE" =~ ^(200|301|302|304)$ ]]; then
        echo -e "  [+] Endpoint: http://localhost:8080${ep} (HTTP ${STATUS_CODE}) --> ${GREEN}[ONLINE]${NC}"
    else
        echo -e "  [-] Endpoint: http://localhost:8080${ep} (HTTP ${STATUS_CODE}) --> ${RED}[HTTP ${STATUS_CODE}]${NC}"
    fi
done
echo -e "${BLUE}====================================================${NC}"
