#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
timestamp="$(date +%Y%m%d-%H%M%S)"

cd "$project_dir"
mkdir -p backup

docker compose exec -T epgstation \
  npm run backup "backup/epgstation-${timestamp}.json"

docker compose exec -T mariadb \
  mariadb-dump --single-transaction -u epgstation -pepgstation epgstation \
  | gzip > "backup/mariadb-${timestamp}.sql.gz"

echo "Backup written to $project_dir/backup"
