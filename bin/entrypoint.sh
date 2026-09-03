#!/bin/bash
# Renders SolrWayback's two property files, starts Solr, then runs Tomcat in
# the foreground. Both are stopped cleanly on SIGTERM.
set -euo pipefail

SW_HOME="${SW_HOME:-/opt/solrwayback}"
CATALINA_HOME="${CATALINA_HOME:-${SW_HOME}/tomcat-9}"
SOLR_BIN="${SW_HOME}/solr-9/bin/solr"
SOLR_PORT="${SW_SOLR_INTERNAL_PORT:-8983}"

# Host-facing port, used only for wayback.baseurl (the browser must be able to
# reach that URL, so it is the published port, not the internal one).
SW_HTTP_PORT="${SW_HTTP_PORT:-8090}"
SW_HEAP="${SW_HEAP:-4g}"
SOLR_URL="http://localhost:${SOLR_PORT}/solr/netarchivebuilder"

log() { printf '[entrypoint] %s\n' "$*"; }

# --- properties ------------------------------------------------------------
# Replaces key=value in place if present (commented or not), appends otherwise.
set_prop() {
    local key="$1" value="$2" file="$3"
    if grep -qE "^[#[:space:]]*${key//./\\.}=" "$file"; then
        # Rewrite in place. '|' as the sed delimiter since values contain '/'.
        sed -i -E "s|^[#[:space:]]*${key//./\\.}=.*|${key}=${value}|" "$file"
        # Upstream ships commented platform variants of some keys (e.g. a
        # Windows screenshot path), so the substitution can produce the same
        # line twice. Keep the first, drop the rest.
        awk -v k="${key}=" 'index($0, k) == 1 { if (seen++) next } { print }' \
            "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    else
        printf '\n%s=%s\n' "$key" "$value" >> "$file"
    fi
}

render_properties() {
    local src dst name
    for name in solrwayback.properties solrwaybackweb.properties; do
        src="${SW_HOME}/properties/${name}"
        dst="${HOME}/${name}"

        # An operator-supplied file wins outright, no substitution applied.
        if [[ -f "${SW_HOME}/conf-in/${name}" ]]; then
            log "using operator-supplied ${name} from conf-in/"
            cp "${SW_HOME}/conf-in/${name}" "$dst"
            continue
        fi

        cp "$src" "$dst"
        set_prop wayback.baseurl "http://localhost:${SW_HTTP_PORT}/solrwayback/" "$dst"
    done

    # Solr is reached in-container, so this is always the internal port.
    set_prop solr.server "http://localhost:${SOLR_PORT}/solr/netarchivebuilder/" \
             "${HOME}/solrwayback.properties"

    # Screenshot previews are deliberately not supported in this image (no
    # Chromium); repoint the temp dir off the upstream sample's /home/xxx path.
    set_prop screenshot.temp.imagedir "/tmp/solrwayback_screenshots/" \
             "${HOME}/solrwayback.properties"
    mkdir -p /tmp/solrwayback_screenshots
}

# --- lifecycle -------------------------------------------------------------
TOMCAT_PID=""

shutdown() {
    log "shutting down"
    if [[ -n "$TOMCAT_PID" ]]; then
        "${CATALINA_HOME}/bin/catalina.sh" stop 20 -force >/dev/null 2>&1 || true
    fi
    "$SOLR_BIN" stop -p "$SOLR_PORT" >/dev/null 2>&1 || true
    log "stopped"
    exit 0
}
trap shutdown SIGTERM SIGINT

wait_for_solr() {
    local i
    for i in $(seq 1 90); do
        if curl -fsS "http://localhost:${SOLR_PORT}/solr/admin/info/system" >/dev/null 2>&1; then
            log "Solr is up"
            return 0
        fi
        sleep 2
    done
    log "ERROR: Solr did not become ready in 180s"
    return 1
}

log "rendering properties into ${HOME}"
render_properties

log "starting Solr (cloud mode, heap ${SW_HEAP}, port ${SOLR_PORT})"
"$SOLR_BIN" start -c -m "$SW_HEAP" -p "$SOLR_PORT"
wait_for_solr

log "starting Tomcat on ${SW_HTTP_INTERNAL_PORT:-8080} (published as ${SW_HTTP_PORT})"
"${CATALINA_HOME}/bin/catalina.sh" run &
TOMCAT_PID=$!

log "SolrWayback will be available at http://localhost:${SW_HTTP_PORT}/solrwayback/"

# Index any WARCs that have not been processed yet, once the UI is serving.
# Runs in the background so the site is usable immediately; already-indexed
# files are skipped, so a restart with nothing new costs a couple of seconds.
if [[ "${AUTO_INDEX:-true}" == "true" ]]; then
    (
        for _ in $(seq 1 60); do
            curl -fsS "http://localhost:${SW_HTTP_INTERNAL_PORT:-8080}/solrwayback/" \
                >/dev/null 2>&1 && break
            sleep 5
        done
        log "auto-index: checking for new WARCs"
        /usr/local/bin/index 2>&1 | sed 's/^/[auto-index] /'
        log "auto-index: done"
    ) &
else
    log "auto-index disabled; index manually with: docker compose exec solrwayback index"
fi

# `wait` returns immediately when a trapped signal arrives, so loop until the
# child is genuinely gone.
while kill -0 "$TOMCAT_PID" 2>/dev/null; do
    wait "$TOMCAT_PID" || true
done
