#!/usr/bin/env bash
# ==============================================================================
# Enterprise Branch Office - Automated Disaster Recovery Backup
# ==============================================================================
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS=7
mkdir -p "${BACKUP_DIR}"
echo "[INFO] Starting backup: ${TIMESTAMP}..."
# 1. Database Hot Dump
echo "[INFO] Exporting MariaDB SQL dump..."
if docker exec branch-mariadb mariadb-dump -u root -p"$(grep DB_ROOT_PASSWORD "${PROJECT_DIR}/.env" | cut -d '=' -f2)" --all-databases 2>/dev/null | gzip > "${BACKUP_DIR}/db_dump_${TIMESTAMP}.sql.gz"; then
    echo "[SUCCESS] Database backed up: db_dump_${TIMESTAMP}.sql.gz"
elif podman exec branch-mariadb mariadb-dump -u root -p"$(grep DB_ROOT_PASSWORD "${PROJECT_DIR}/.env" | cut -d '=' -f2)" --all-databases 2>/dev/null | gzip > "${BACKUP_DIR}/db_dump_${TIMESTAMP}.sql.gz"; then
    echo "[SUCCESS] Database backed up: db_dump_${TIMESTAMP}.sql.gz"
else
    echo "[WARN] Database backup skipped (container not running or password mismatch)."
fi
# 2. Configuration & Data Directory Archive
echo "[INFO] Archiving configurations..."
tar -czf "${BACKUP_DIR}/configs_${TIMESTAMP}.tar.gz" -C "${PROJECT_DIR}" configs .env.example
# 3. Enforce Retention Policy (delete backups older than 7 days)
echo "[INFO] Enforcing retention policy (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -type f -name "*.gz" -mtime +"${RETENTION_DAYS}" -delete
echo "[SUCCESS] Backup complete! Backups stored in: ${BACKUP_DIR}"
