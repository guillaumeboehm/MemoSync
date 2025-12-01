#!/bin/sh

backend_root="$(dirname "$0")"

echo "Activating database..."
"${backend_root}/utils/activate_db.sh" && sleep 3

docker compose up -d
"${backend_root}/utils/setup_dbs.sh"
"${backend_root}/node_modules/pm2/bin/pm2" start ecosystem.config.cjs
