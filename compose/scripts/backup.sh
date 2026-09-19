#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
timestamp="$(date +%Y%m%d-%H%M%S)"

cd "$project_dir"
mkdir -p backup

docker compose exec -T epgstation \
  npm run backup "backup/epgstation-${timestamp}.json"

docker compose exec -T mariadb \
  sh -ec 'export MYSQL_PWD="$(cat /run/secrets/mariadb_password)"; exec mariadb-dump --single-transaction -u epgstation epgstation' \
  | gzip > "backup/mariadb-${timestamp}.sql.gz"

echo "Backup written to $project_dir/backup"
