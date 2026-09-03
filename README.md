# SolrWayback in Docker

Runs [SolrWayback](https://github.com/netarchivesuite/solrwayback) 5.4.3 (Solr 9 +
Tomcat 9) in a single container. You supply a folder of WARC files, index them,
and browse the archive at `http://localhost:8090/solrwayback/`.

The image is built from the pinned upstream release zip, verified by SHA-256, so
this repo holds only config — no binaries, no bundle checkout, nothing
machine-specific.

## Quick start

```bash
cp .env.example .env          # then edit SW_WARC_DIR
docker compose up -d          # first run builds the image (~1 GB download)
```

Drop `.warc` / `.warc.gz` files into the folder `SW_WARC_DIR` points at, then:

```bash
docker compose exec solrwayback index
```

Open <http://localhost:8090/solrwayback/>. Indexing is incremental — rerun the
same command after adding more WARCs and only the new ones are processed.

## Configuration

All settings live in `.env` (git-ignored; copy from `.env.example`):

| Variable | Default | Notes |
|---|---|---|
| `SW_WARC_DIR` | `./warcs` | Host folder holding your WARCs. Mounted read-only. |
| `SW_HTTP_PORT` | `8090` | Host port for the web UI. |
| `SW_SOLR_PORT` | `8990` | Host port for the Solr admin UI. |
| `SW_HEAP` | `3g` | Solr heap. See memory note below. |
| `INDEX_THREADS` | `2` | Parallel indexer processes, each a JVM with a 1 GB heap. |
| `SW_VERSION` | `5.4.3` | Upstream release to build from. |

Changing a port and running `docker compose up -d` is enough — the property
files are regenerated on every start.

The defaults are `8090` and `8990`, not Solr and Tomcat's usual `8983` and
`8080`, so this stack can run alongside another SolrWayback proxied in on the
standard ports. Inside the container the services still listen on 8080 and
8983; only the published host ports differ, and nothing about the index depends
on either.

### Memory

Budget roughly `SW_HEAP + INDEX_THREADS × 1 GB + 1 GB` and give Docker Desktop
more than that (Settings → Resources). On an 8 GB allocation, `SW_HEAP=3g` with
`INDEX_THREADS=2` fits comfortably. Raise `SW_HEAP` to `4g` or beyond once you've given Docker Desktop 10 GB or more.

### Overriding the property files

The two SolrWayback property files are generated at startup from the ones
shipped in the bundle, with the Solr URL and base URL substituted. To take full
control, drop your own `solrwayback.properties` or `solrwaybackweb.properties`
into `./conf/` — a file present there is used verbatim, with no substitution.

## Indexing

```bash
docker compose exec solrwayback index                        # all of warcs1
docker compose exec solrwayback index warcs1/one.warc.gz     # a single WARC
```

Progress logs land in the `index-status` volume, one per WARC. That is also how
already-indexed files are skipped; delete a WARC's `.log` to force a reindex.

As a rough guide, 6.2 GB across 19 WARCs took **19 minutes** with
`INDEX_THREADS=4` on an M4 Pro with 6 CPUs and 12 GB allotted to Docker — call
it 20 GB/hour. It scales with `INDEX_THREADS` until you run out of RAM.

Two things to know:

- **WARC filenames must be unique.** The upstream indexer refuses to run on
  duplicate basenames, even across different subfolders. The wrapper checks for
  this up front and names the offenders.
- **Documents appear only after a commit.** The wrapper issues one when
  indexing finishes; results are visible immediately after.

## How state is stored

| Path | Storage | Why |
|---|---|---|
| `${SW_WARC_DIR}` → `/opt/solrwayback/indexing/warcs1` | bind, read-only | You need to add files from the host. |
| `/opt/solrwayback/solr-9/server/solr` | named volume `solr-home` | The index. Write-heavy; a bind mount here would go through VirtioFS on Docker Desktop and be markedly slower. |
| `/opt/solrwayback/indexing/status` | named volume `index-status` | Tracks which WARCs are done. Losing it causes duplicate documents on the next run. |

The Solr home volume is populated from the image on first run, which is what
seeds the empty `netarchivebuilder` collection along with its ZooKeeper state.
The collection is defined in ZooKeeper, not on disk, so the whole `server/solr`
directory is a single unit of state — don't split it across mounts.

To start over:

```bash
docker compose down -v      # deletes the index and indexing history
```

Your WARCs are untouched; the mount is read-only.

## The one thing not to change

The container-side WARC path in `compose.yaml`:

```
/opt/solrwayback/indexing/warcs1
```

The indexer records the path it sees into `source_file_path` on every document,
permanently. Change that path and every already-indexed document loses playback
until it is reindexed. The host side (`SW_WARC_DIR`) is the knob; the container
side is a constant, which is exactly what makes an index built on one machine
work on another.

## Not included

Screenshot previews are omitted deliberately — they need Chromium, which roughly
doubles the image size. Everything else in SolrWayback works, playback included.

## Troubleshooting

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
