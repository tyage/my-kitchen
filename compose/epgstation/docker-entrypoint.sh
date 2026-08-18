#!/usr/bin/env bash
set -euo pipefail

readonly secret_file=/run/secrets/mariadb_password
readonly source_config=/app/config-source/config.yml
readonly runtime_config=/app/config/config.yml

if [[ ! -s "${secret_file}" ]]; then
  echo "MariaDB password secret is missing or empty: ${secret_file}" >&2
  exit 1
fi

mkdir -p /app/config
cp -a /app/config-source/. /app/config/

node <<'NODE'
const fs = require('node:fs');

const token = '__MARIADB_PASSWORD_JSON__';
const source = fs.readFileSync('/app/config-source/config.yml', 'utf8');
const password = fs.readFileSync('/run/secrets/mariadb_password', 'utf8').trimEnd();

if (!source.includes(token)) {
  throw new Error(`Database password token is missing from config.yml: ${token}`);
}

fs.writeFileSync('/app/config/config.yml', source.replace(token, JSON.stringify(password)));
NODE

exec npm start
