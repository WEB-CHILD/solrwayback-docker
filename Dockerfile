# SolrWayback, containerised.
#
# Built from the pinned upstream release zip rather than from a local bundle
# tree, so the image is reproducible on any machine and this repo stays tiny.
FROM eclipse-temurin:17-jre

ARG SW_VERSION=5.4.3
ARG SW_SHA256=833200a063ad2b8787d0068854a8f4fb27ce7a8b9658cd59b54d8ce593a6602c
ARG SW_UID=1000

# Links the published package to its GitHub repository. Without this label the
# package is orphaned in the org and has to be managed by hand; with it, the
# package inherits the repo's access and appears on the repo page.
ARG SW_SOURCE=https://github.com/WEB-CHILD/solrwayback-docker
LABEL org.opencontainers.image.source="${SW_SOURCE}" \
      org.opencontainers.image.description="SolrWayback ${SW_VERSION}, ready to run" \
      org.opencontainers.image.licenses="Apache-2.0"

# SW_HOME is a FIXED container path. See the warning in compose.yaml before
# changing it: it is recorded inside the Solr index for every document.
ENV SW_HOME=/opt/solrwayback \
    CATALINA_HOME=/opt/solrwayback/tomcat-9 \
    SOLR_ULIMIT_CHECKS=false \
    SW_SOLR_INTERNAL_PORT=8983 \
    SW_HTTP_INTERNAL_PORT=8080

# curl: the indexer's readiness ping and post-index Solr commit (the JRE image
# ships neither curl nor wget, and without one the commit is silently skipped
# and freshly indexed documents stay invisible).
# procps/lsof: used by Solr's own start/stop scripts.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip procps lsof \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 bases ship an "ubuntu" account already holding uid 1000.
RUN userdel -r ubuntu 2>/dev/null || true; \
    useradd --create-home --uid "${SW_UID}" --shell /bin/bash solrwayback

WORKDIR /opt
RUN curl -fsSL -o sw.zip \
        "https://github.com/netarchivesuite/solrwayback/releases/download/${SW_VERSION}/solrwayback_package_${SW_VERSION}.zip" \
    && echo "${SW_SHA256}  sw.zip" | sha256sum -c - \
    && unzip -q sw.zip \
    && mv "solrwayback_package_${SW_VERSION}" solrwayback \
    && rm sw.zip

# warcs1 is the bind-mount point for user WARCs; status/ and tika_tmp/ must
# exist and be writable before the volumes are populated from them.
RUN mkdir -p "${SW_HOME}/indexing/warcs1" \
             "${SW_HOME}/indexing/status/tmp" \
             "${SW_HOME}/indexing/tika_tmp" \
    && chown -R solrwayback:solrwayback "${SW_HOME}"

COPY --chown=root:root bin/entrypoint.sh bin/index /usr/local/bin/
RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/index

USER solrwayback
WORKDIR /opt/solrwayback

EXPOSE 8080 8983

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
    CMD curl -fsS "http://localhost:8080/solrwayback/" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
