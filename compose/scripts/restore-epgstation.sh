#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "usage: $0 /path/to/epgstation-backup.json" >&2
  exit 2
fi

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_file="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

cd "$project_dir"
mkdir -p backup
cp "$source_file" backup/restore.json

docker compose up -d mariadb mirakc
docker compose run --rm epgstation npm run restore backup/restore.json
docker compose up -d epgstation
