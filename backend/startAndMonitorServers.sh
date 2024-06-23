#!/bin/sh

root="$(dirname "$0")"
cd "$root" || return
./startServers.sh
./node_modules/pm2/bin/pm2 monit
./node_modules/pm2/bin/pm2 stop ecosystem.config.cjs
docker compose down
