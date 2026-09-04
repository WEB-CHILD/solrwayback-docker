# SolrWayback in Docker

Runs [SolrWayback](https://github.com/netarchivesuite/solrwayback) 5.4.3 in a
single container. You supply a folder of WARC files, it indexes them, and you
browse your archive in the browser.

## Getting started

**Install Docker first.** On macOS and Windows that means
[Docker Desktop](https://www.docker.com/products/docker-desktop/); on Linux,
[Docker Engine](https://docs.docker.com/engine/install/).

1. **Download this folder.** Go to
   <https://github.com/WEB-CHILD/solrwayback-docker>, click the green **Code**
   button, choose **Download ZIP**, then unzip it. Put the unzipped folder
   somewhere permanent, e.g. your Documents folder. You can rename it to
   anything you like.

2. **Put your web archives in the `warcs` folder** — any `.warc` or `.warc.gz`
   files. You can add more later.

3. **Double-click the Start file for your system:**

   | System | Start | Stop |
   |---|---|---|
   | macOS | `Start SolrWayback.command` | `Stop SolrWayback.command` |
   | Windows | `Start SolrWayback.bat` | `Stop SolrWayback.bat` |
   | Linux | `Start SolrWayback.sh` | `Stop SolrWayback.sh` |

That is it. A terminal window opens and reports progress; the first run takes a
few minutes while it downloads SolrWayback. Your browser opens automatically at
`http://localhost:8090/solrwayback/` when it is ready.

Large archives take a while to index — roughly an hour per 15 GB — and the site
fills in as it goes, so you can search while it works.

**To add more archives later:** drop them in the `warcs` folder and double-click
`Start SolrWayback` again. Files already indexed are skipped.

**To shut down:** double-click `Stop SolrWayback`. Your archive is kept.

## First-run notes

<details>
<summary><b>macOS</b></summary>

The system may refuse to open a downloaded script. Right-click
`Start SolrWayback.command` → **Open** → **Open**. You only do this once.

</details>

<details>
<summary><b>Windows</b></summary>

If you point `SW_WARC_DIR` somewhere other than the default `warcs` folder,
write the path with forward slashes — `C:/Users/me/archives`, not
`C:\Users\me\archives`.

Docker Desktop's memory limit is set in `.wslconfig`, not in the Docker Desktop
settings window.

</details>

<details>
<summary><b>Linux</b></summary>

Double-clicking may need **Run in Terminal** rather than opening an editor, or
run `./"Start SolrWayback.sh"` from a terminal.

The container reads your WARCs as user id 1000; on Linux that id is taken
literally, so if indexing finds nothing, run `chmod -R a+rX warcs`.

As there is no Docker Desktop memory slider the container uses host RAM
directly and it is set with `SW_HEAP`.

</details>

## Something went wrong?

See [troubleshooting](docs/troubleshooting.md).

## Going further

- [Configuration](docs/configuration.md) — ports, memory, `.env` settings, and
  running from the command line
- [Indexing](docs/indexing.md) — manual indexing, performance, and how state is
  stored
- [Releasing](docs/releasing.md) — maintainer only

The image is built from the pinned upstream release zip, verified by SHA-256,
so this repo holds only config.

## License

This repository — the Dockerfile, Compose file, launcher scripts and helper
scripts — is licensed under the Apache License 2.0. See [LICENSE](LICENSE).

SolrWayback itself is a separate project by the Royal Danish Library, also
Apache 2.0 licensed.
<https://github.com/netarchivesuite/solrwayback>
