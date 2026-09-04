# Troubleshooting

**macOS refuses to open the Start script** — right-click
`Start SolrWayback.command` → **Open** → **Open**. You only do this once.

**Linux: indexing finds nothing** — the container reads your WARCs as user id
1000, and on Linux that id is taken literally. Run `chmod -R a+rX warcs`.

**`ports are not available: address already in use`** — something else holds
8090 or 8990. A locally installed SolrWayback bundle uses exactly these ports;
stop it with `./solrwayback_bundle.sh stop`, or set different `SW_HTTP_PORT` /
`SW_SOLR_PORT` values in your `.env` to run both at once.

Find the culprit with:

```bash
lsof -nP -iTCP:8090 -sTCP:LISTEN
```

**Checking which instance you are talking to** — if you have both a container
and a native bundle, `source_file_path` tells them apart. Container-indexed
documents start with `/opt/solrwayback/`, natively indexed ones with a host
path:

```bash
curl -s "http://localhost:8990/solr/netarchivebuilder/select?q=*:*&rows=1&fl=source_file_path"
```

**Indexing was interrupted** — just run `docker compose exec solrwayback index`
again. The wrapper detects WARCs left half-processed, clears their state, and
reprocesses them.
