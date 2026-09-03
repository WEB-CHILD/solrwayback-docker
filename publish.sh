#!/bin/bash
# Maintainer script - not needed by end users.
#
# Builds and publishes the image so users pull instead of building.
# Multi-architecture: Apple Silicon (arm64) and Intel (amd64) Macs both need
# to work, and a single-arch image fails on the other kind.
#
# One-time setup:
#   1. Create a GitHub personal access token with the "write:packages" scope
#      at https://github.com/settings/tokens
#   2. echo "$TOKEN" | docker login ghcr.io -u <your-github-username> --password-stdin
#
# Then: ./publish.sh
set -euo pipefail
cd "$(dirname "$0")"

IMAGE="${SW_IMAGE:-ghcr.io/jorntx/solrwayback}"
VERSION="${SW_VERSION:-5.4.3}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

echo "Publishing ${IMAGE}:${VERSION} for ${PLATFORMS}"

# A dedicated builder is required for multi-platform output.
if ! docker buildx inspect solrwayback-builder >/dev/null 2>&1; then
    docker buildx create --name solrwayback-builder --driver docker-container --bootstrap
fi

docker buildx build \
    --builder solrwayback-builder \
    --platform "$PLATFORMS" \
    --build-arg "SW_VERSION=${VERSION}" \
    --tag "${IMAGE}:${VERSION}" \
    --tag "${IMAGE}:latest" \
    --push \
    .

echo
echo "Published:"
echo "  ${IMAGE}:${VERSION}"
echo "  ${IMAGE}:latest"
echo
echo "Make the package public so users need no login:"
echo "  https://github.com/users/${IMAGE#ghcr.io/}/packages -> package settings -> change visibility"
