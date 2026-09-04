# Configuration

All settings live in `.env` (git-ignored; copy from `.env.example`). No `.env`
file is required — every setting has a working default.

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

## Running from the command line

```bash
docker compose up -d      # start (builds or pulls the image as needed)
docker compose logs -f    # watch progress
docker compose stop       # stop, keeping the index
docker compose down -v    # delete the index and start over
```

To index manually rather than on startup, set `AUTO_INDEX=false` in `.env` and
run `docker compose exec solrwayback index`. See [indexing](indexing.md).

## Ports

The defaults are `8090` and `8990`, not Solr and Tomcat's usual `8983` and
`8080`, so this stack can run alongside another SolrWayback proxied in on the
standard ports. Inside the container the services still listen on 8080 and
8983; only the published host ports differ, and nothing about the index depends
on either.

## Memory

Budget roughly `SW_HEAP + INDEX_THREADS × 1 GB + 1 GB` and give Docker Desktop
more than that (Settings → Resources). On an 8 GB allocation, `SW_HEAP=3g` with
`INDEX_THREADS=2` fits comfortably. Raise `SW_HEAP` to `4g` or beyond once
you've given Docker Desktop 10 GB or more.

On Linux there is no Docker Desktop memory slider — the container uses host RAM
directly, so `SW_HEAP` is the setting that matters.

## Overriding the property files

The two SolrWayback property files are generated at startup from the ones
shipped in the bundle, with the Solr URL and base URL substituted. To take full
control, drop your own `solrwayback.properties` or `solrwaybackweb.properties`
into `./conf/` — a file present there is used verbatim, with no substitution.

## Not included

Screenshot previews are omitted deliberately — they need Chromium, which
roughly doubles the image size. Everything else in SolrWayback works, playback
included.
