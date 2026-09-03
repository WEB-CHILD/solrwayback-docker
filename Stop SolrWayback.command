#!/bin/bash
# Double-click this file in Finder to stop SolrWayback.
cd "$(dirname "$0")" || exit 1

printf '\n=== Stopping SolrWayback ===\n\n'

if ! docker info >/dev/null 2>&1; then
    printf 'Docker Desktop is not running, so SolrWayback is already stopped.\n'
else
    docker compose stop
    printf '\nSolrWayback has been shut down. Your archive is kept.\n'
    printf 'Double-click "Start SolrWayback" to use it again.\n'
fi

printf '\nPress any key to close this window.\n'
read -r -n 1
