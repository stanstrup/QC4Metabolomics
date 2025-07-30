#!/bin/bash
set -e

VERSION="$1"
REGISTRY="ghcr.io/${GITHUB_REPOSITORY_OWNER}/qc4metabolomics"

# Re-tag and push base image
docker pull "$REGISTRY/qc_base:latest"
docker tag "$REGISTRY/qc_base:latest" "$REGISTRY/qc_base:$VERSION"
docker push "$REGISTRY/qc_base:$VERSION"

# Re-tag and push other images
for IMAGE in qc_process qc_shiny qc_converter; do
  docker pull "$REGISTRY/$IMAGE:latest"
  docker tag "$REGISTRY/$IMAGE:latest" "$REGISTRY/$IMAGE:$VERSION"
  docker push "$REGISTRY/$IMAGE:$VERSION"
done
