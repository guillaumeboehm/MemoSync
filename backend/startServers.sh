#!/bin/sh

root="$(dirname "$0")"
cd "$root" || return
docker compose up -d
./utils/setup_dbs.sh
./node_modules/pm2/bin/pm2 start ecosystem.config.cjs
