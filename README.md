# SolrWayback in Docker

Runs [SolrWayback](https://github.com/netarchivesuite/solrwayback) 5.4.3 (Solr 9 +
Tomcat 9) in a single container. You supply a folder of WARC files, index them,
and browse the archive at `http://localhost:8090/solrwayback/`.

The image is built from the pinned upstream release zip, verified by SHA-256, so
this repo holds only config — no binaries, no bundle checkout, nothing
machine-specific.

## Setting up (no terminal needed)

Docker must be installed. On macOS and Windows that means Docker Desktop:
<https://www.docker.com/products/docker-desktop/>. On Linux, Docker Engine:
<https://docs.docker.com/engine/install/>. Nothing else — no Java, no Solr,
no Tomcat.

1. **Download this folder** and put it somewhere permanent, e.g. your
   Documents folder.
2. **Put your web archives in the `warcs` folder** — any `.warc` or `.warc.gz`
   files. You can add more later.
3. **Double-click the Start file for your system:**

   | System | Start | Stop |
   |---|---|---|
   | macOS | `Start SolrWayback.command` | `Stop SolrWayback.command` |
   | Windows | `Start SolrWayback.bat` | `Stop SolrWayback.bat` |
   | Linux | `Start SolrWayback.sh` | `Stop SolrWayback.sh` |

That is it. A terminal window opens and reports progress; the first run takes a
few minutes while it downloads SolrWayback. Your browser opens automatically
when it is ready.

Any new archive files are indexed automatically. Large archives take a while —
roughly an hour per 15 GB — and the site fills in as it goes, so you can search
while it works.

To add more archives later: drop them in the `warcs` folder and double-click
`Start SolrWayback` again. Files already indexed are skipped.

To shut down: double-click `Stop SolrWayback`. Your archive is kept.

### First-run notes per system

> **macOS:** the system may refuse to open a downloaded script. Right-click
> `Start SolrWayback.command` → **Open** → **Open**. You only do this once.

> **Windows:** if you point `SW_WARC_DIR` somewhere other than the default
> `warcs` folder, write the path with forward slashes — `C:/Users/me/archives`,
> not `C:\Users\me\archives`. Docker Desktop's memory limit is set in
> `.wslconfig`, not in the Docker Desktop settings window.

> **Linux:** double-clicking may need **Run in Terminal** rather than opening
> an editor, or run `./"Start SolrWayback.sh"` from a terminal. The container
> reads your WARCs as user id 1000; on Linux that id is taken literally, so if
> indexing finds nothing, run `chmod -R a+rX warcs`. There is no Docker Desktop
> memory slider — the container uses host RAM directly, so `SW_HEAP` is the
> setting that matters.

### From the command line

If you would rather drive it yourself:

```bash
docker compose up -d      # start (builds or pulls the image as needed)
docker compose logs -f    # watch progress
docker compose stop       # stop, keeping the index
docker compose down -v    # delete the index and start over
```

No `.env` file is required — every setting has a working default. Copy
`.env.example` to `.env` only if you want to change something.

To index manually rather than on startup, set `AUTO_INDEX=false` in `.env` and
run:

```bash
docker compose exec solrwayback index
```

## Publishing the image (maintainer only)

Users pull a prebuilt image rather than building it themselves. The image lives
in the GitHub Container Registry (`ghcr.io`) under the WEB-CHILD organisation,
as `ghcr.io/web-child/solrwayback`.

**One-time setup**

1. Create a **classic** personal access token at
   <https://github.com/settings/tokens> with the `write:packages` scope.
   Fine-grained tokens cannot write to the container registry.
2. If WEB-CHILD enforces SAML SSO, click **Configure SSO** on the token and
   authorise the organisation. Without that, every push fails with 403.
3. Log Docker in. The username is your own GitHub login, not the org name --
   the token is what grants access to the org:

   ```bash
   echo "$TOKEN" | docker login ghcr.io -u <your-github-username> --password-stdin
   ```

**Every release**

```bash
./publish.sh                 # current version, from SW_VERSION in the script
SW_VERSION=5.5.0 ./publish.sh   # or override it
```

The script builds for `linux/amd64` **and** `linux/arm64` and pushes both under
one tag. This is not optional: a plain `docker build && docker push` from an
Apple Silicon Mac produces an arm64-only image that fails outright on every
Intel Mac. `docker buildx` is what makes the two-architecture push possible; the
script creates its builder on first run.

Two tags are pushed each time: `:5.4.3` (immutable, what `compose.yaml` pins)
and `:latest` (a moving pointer, for convenience).

**After the first push only**

Open <https://github.com/orgs/WEB-CHILD/packages>, pick `solrwayback`, then
**Package settings -> Change visibility -> Public**. New packages are private by
default, and a private one prompts every user for a login, which defeats the
point. The setting persists across later pushes.

If no published image exists, or the pull fails, `docker compose up` and the
Start script fall back to building locally, so the project works either way --
users just wait through a long first run.

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

Measured on an M4 Pro with 6 CPUs and 12 GB allotted to Docker:

| WARCs | Size | Threads | Time |
|---|---|---|---|
| 19 | 6.2 GB | 4 | 19 min (~20 GB/h) |
| 2 | 0.9 GB | 2 | 4 min (~15 GB/h) |

It scales with `INDEX_THREADS` until you run out of RAM.

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

## License

This repository — the Dockerfile, Compose file, launcher scripts and helper
scripts — is licensed under the Apache License 2.0. See [LICENSE](LICENSE).

SolrWayback itself is a separate project by the Royal Danish Library, also
Apache 2.0 licensed. The image downloads its official release bundle at build
time rather than redistributing a modified copy:
<https://github.com/netarchivesuite/solrwayback>
