#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

docker compose config --quiet
docker compose ps
curl -fsS http://localhost:40772/api/version
curl -fsS http://localhost:8888/api/config >/dev/null

if [[ -e /dev/dri/renderD128 ]]; then
  vainfo --display drm --device /dev/dri/renderD128 >/dev/null
else
  echo "warning: /dev/dri/renderD128 is missing" >&2
fi
