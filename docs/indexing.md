# Indexing

Indexing runs automatically on startup. To drive it yourself:

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
