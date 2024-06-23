#!/bin/sh

mongosh --file "$(dirname "$0")/mongosh_scripts/init_dbs.js"
