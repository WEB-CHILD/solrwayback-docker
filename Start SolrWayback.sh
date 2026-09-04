#!/bin/bash
# Linux. Double-click and choose "Run in Terminal", or run it from a terminal:
#   ./"Start SolrWayback.sh"
cd "$(dirname "$0")" || exit 1

say()  { printf '\n%s\n' "$*"; }
fail() { printf '\n%s\n\nPress any key to close this window.\n' "$*"; read -r -n 1; exit 1; }

printf '\n=== Starting SolrWayback ===\n'

if ! command -v docker >/dev/null 2>&1; then
    fail "Docker does not seem to be installed.
Install Docker Engine from https://docs.docker.com/engine/install/ and run this again."
fi

# On Linux the daemon is a system service, not a desktop app, so there is
# nothing to launch the way Docker Desktop is launched on macOS.
if ! docker info >/dev/null 2>&1; then
    fail "Cannot talk to the Docker daemon. Try:

  sudo systemctl start docker

If that works but this still fails, your user is probably not in the 'docker'
group. Run 'sudo usermod -aG docker \$USER', then log out and back in."
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
    xdg-open "${URL}/solrwayback/" >/dev/null 2>&1 &
    cat <<MSG

SolrWayback is running.

  Address:    ${URL}/solrwayback/
  WARC files: $(pwd)/warcs

To add web archives, put .warc or .warc.gz files in the "warcs" folder,
then run this Start file again. New files are indexed automatically -
that can take a while, and the archive fills in as it goes.

Note: the container reads your WARCs as user id 1000. If indexing finds
nothing, make them readable to everyone:  chmod -R a+rX warcs

To shut down, run "Stop SolrWayback.sh".
MSG
else
    say "SolrWayback did not respond in time. Check that Docker is running, then try again."
fi

printf '\nPress any key to close this window.\n'
read -r -n 1
