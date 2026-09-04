# Releasing (maintainer only)

Users pull a prebuilt image rather than building it themselves. The image lives
in the GitHub Container Registry (`ghcr.io`) under the WEB-CHILD organisation,
as `ghcr.io/web-child/solrwayback`.

Publishing is automated by `.github/workflows/publish.yml`: pushing a tag shaped
`v5.5.0` builds and pushes the image. No personal access token and no
`docker login` are needed — GitHub mints a scoped token for each run.

## Every release

1. Get the checksum of the new upstream zip. Nothing publishes it, so compute
   it from the file you intend to ship:

   ```bash
   VER=5.5.0
   curl -fL -o /tmp/sw.zip \
     "https://github.com/netarchivesuite/solrwayback/releases/download/${VER}/solrwayback_package_${VER}.zip"
   shasum -a 256 /tmp/sw.zip
   ```

2. Update **both** `SW_VERSION` and `SW_SHA256` in the `Dockerfile`. The
   workflow takes the version from the tag but always reads the checksum from
   the `Dockerfile`, so a mismatched pair fails the build at the checksum step
   rather than publishing a mislabelled image.

3. Commit, then tag and push:

   ```bash
   git commit -am "SolrWayback 5.5.0"
   git push
   git tag v5.5.0 && git push origin v5.5.0
   ```

Watch the run on the repository's **Actions** tab. Each run pushes two tags:
`:5.5.0` (immutable, what `compose.yaml` pins) and `:latest` (a moving
pointer). Both are built for `linux/amd64` **and** `linux/arm64`, which is not
optional: a single-architecture image fails outright on the other kind of
machine.

To rebuild without a new version — after a `Dockerfile` fix, say — use the
**Run workflow** button on the Actions tab instead of tagging.

## Break glass

If Actions is unavailable, the same push can be done by hand. It needs a
**classic** personal access token with the `write:packages` scope
(<https://github.com/settings/tokens>; fine-grained tokens cannot write to the
container registry), SSO-authorised for WEB-CHILD if the org enforces it:

```bash
echo "$TOKEN" | docker login ghcr.io -u <your-github-username> --password-stdin
docker buildx build --platform linux/amd64,linux/arm64 \
    --build-arg SW_VERSION=5.5.0 \
    -t ghcr.io/web-child/solrwayback:5.5.0 \
    -t ghcr.io/web-child/solrwayback:latest --push .
```

The username is your own GitHub login, never the org name; the token is what
grants access to the org.

If no published image exists, or the pull fails, `docker compose up` and the
Start script fall back to building locally, so the project works either way —
users just wait through a long first run.
