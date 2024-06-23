#!/bin/sh

default_env=$(for e in $(for f in *.js; do grep -oP "process\.env\.\w+" "$f"; done | sed 's/process.env.//g' | sort | uniq); do echo "$e=\"\""; done)

echo "$default_env" > .env.default
