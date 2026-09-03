#!/bin/bash
# Double-click this file in Finder to start SolrWayback.
cd "$(dirname "$0")" || exit 1

say()  { printf '\n%s\n' "$*"; }
fail() { printf '\n%s\n\nPress any key to close this window.\n' "$*"; read -r -n 1; exit 1; }

printf '\n=== Starting SolrWayback ===\n'

if ! command -v docker >/dev/null 2>&1; then
    fail "Docker Desktop does not seem to be installed.
Install it from https://www.docker.com/products/docker-desktop/ and run this again."
fi

# Docker Desktop may be installed but not running; start it and wait.
if ! docker info >/dev/null 2>&1; then
    say "Starting Docker Desktop, please wait..."
    open -a Docker 2>/dev/null
    for _ in $(seq 1 60); do
        docker info >/dev/null 2>&1 && break
        sleep 5
    done
    docker info >/dev/null 2>&1 || fail "Docker Desktop did not start.
Open it manually, wait until it says 'Running', then run this again."
fi

# Prefer a published image; fall back to building locally if that is not
# available (no network, or the image was never pushed).
say "Getting SolrWayback (this can take several minutes the first time)..."
if ! docker compose pull --quiet 2>/dev/null; then
    say "No published image available, building locally instead..."
    docker compose build || fail "Could not build SolrWayback. See the messages above."
fi

say "Starting up..."
docker compose up -d || fail "Could not start SolrWayback. See the messages above."

say "Waiting for SolrWayback to be ready..."
URL="http://localhost:$(grep -E '^SW_HTTP_PORT=' .env 2>/dev/null | cut -d= -f2 || true)"
[ "$URL" = "http://localhost:" ] && URL="http://localhost:8090"
for _ in $(seq 1 60); do
    curl -fsS "${URL}/solrwayback/" >/dev/null 2>&1 && break
    sleep 5
done

if curl -fsS "${URL}/solrwayback/" >/dev/null 2>&1; then
    open "${URL}/solrwayback/"
    cat <<MSG

SolrWayback is running.

  Address:    ${URL}/solrwayback/
  WARC files: $(pwd)/warcs

To add web archives, put .warc or .warc.gz files in the "warcs" folder,
then run this Start file again. New files are indexed automatically -
that can take a while, and the archive fills in as it goes.

To shut down, double-click "Stop SolrWayback".
MSG
else
    say "SolrWayback did not respond in time. Check Docker Desktop is running, then try again."
fi

printf '\nPress any key to close this window.\n'
read -r -n 1
