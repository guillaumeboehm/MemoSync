#!/bin/sh

backend_root="$(dirname "$0")"

"${backend_root}/startServers.sh"
"${backend_root}/node_modules/pm2/bin/pm2" monit

"${backend_root}/node_modules/pm2/bin/pm2" stop ecosystem.config.cjs
docker compose down
"${backend_root}/utils/deactivate_db.sh"
