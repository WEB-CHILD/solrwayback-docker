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

   On macOS the first double-click is blocked with a warning about malware.
   That is normal for downloaded scripts — see [macOS](#first-run-notes) below
   for the one-time fix.

That is it. A terminal window opens and reports progress; the first run takes a
few minutes while it downloads SolrWayback. Your browser opens automatically at
`http://localhost:8090/solrwayback/` when it is ready.

Large archives take a while to index — roughly an hour per 15 GB — and the site
fills in as it goes, so you can search while it works.

**To follow what it is doing:** open Docker Desktop, click the `solrwayback`
container, and select the **Logs** tab. Indexing progress, warnings and errors
all show up there. This is also the first place to look if something seems
stuck or a WARC file does not turn up in search results. The logs keep running
even after you close the terminal window that started it.

**To add more archives later:** drop them in the `warcs` folder and double-click
`Start SolrWayback` again. Files already indexed are skipped, so nothing is
done twice.

If the container is already set up, you do not need the start script for this —
stopping and starting `solrwayback` from Docker Desktop does the same thing.
Indexing runs every time the container starts, and picks up whatever is in the
`warcs` folder at that moment.

**To shut down:** double-click `Stop SolrWayback`, or open Docker Desktop and
press the stop button next to the `solrwayback` container. Either way your
archive is kept. Once the container exists, you can start and stop it from
Docker Desktop from then on, without using the scripts at all.

## First-run notes

<details open>
<summary><b>macOS</b></summary>

**macOS will refuse to open the script the first time.** You get a dialog
saying Apple *"could not verify"* it is free of malware, and the only buttons
are **Move to Trash** and **Done**. This is expected — macOS blocks every
script downloaded from the internet that has not been signed by a paid Apple
developer account. Nothing is wrong with the file.

To allow it, once:

1. Click **Done**. (Not Move to Trash.)
2. Open **System Settings** → **Privacy & Security**.
3. Scroll down to the **Security** section. There is a line saying
   *"Start SolrWayback.command" was blocked to protect your Mac*, with an
   **Open Anyway** button.
4. Click **Open Anyway** and confirm with Touch ID or your password.
5. Double-click `Start SolrWayback.command` again. It runs.

Do steps 1–4 straight after each other — that Security line only appears once
something has just been blocked, and it disappears again after a while. If you
do not see it, double-click the file again to trigger the block, then go back
to Privacy & Security.

Older instructions tell you to right-click the file and choose **Open**. That
no longer works: macOS 15 removed the shortcut, so System Settings is now the
only way through.

**You will not need to do this for `Stop SolrWayback.command`** if you stop the
container from Docker Desktop instead — see below.

If you are comfortable with the terminal, you can skip all of the above.
Scripts you launch yourself from a shell are not checked by macOS, so this just
works:

```sh
cd ~/Downloads/solrwayback-docker-main   # wherever you put the folder
./"Start SolrWayback.command"
```

Or clear the download flag once and double-clicking behaves normally
afterwards:

```sh
xattr -dr com.apple.quarantine ~/Downloads/solrwayback-docker-main
```

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
