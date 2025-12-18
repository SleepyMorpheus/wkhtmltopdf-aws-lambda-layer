#!/bin/bash

set -e

# Build for Amazon Linux 2 (default)
AL_VERSION="${1:-al2}"

if [ "$AL_VERSION" = "al2" ]; then
    DOCKERFILE="Dockerfile"
    DOCKER_IMAGE_TAG="wkhtmltopdf:amazonlinux2"
    LAYER_ZIP="layer.zip"
elif [ "$AL_VERSION" = "al2023" ]; then
    DOCKERFILE="Dockerfile.al2023"
    DOCKER_IMAGE_TAG="wkhtmltopdf:amazonlinux2023"
    LAYER_ZIP="layer-al2023.zip"
else
    echo "Error: Unsupported Amazon Linux version '$AL_VERSION'"
    echo "Usage: $0 [al2|al2023]"
    exit 1
fi

echo "Building layer for Amazon Linux $AL_VERSION..."
rm -f $LAYER_ZIP 1>/dev/null

docker build -t $DOCKER_IMAGE_TAG -f $DOCKERFILE .
CONTAINER=$(docker run -d $DOCKER_IMAGE_TAG)
docker cp $CONTAINER:/layer.zip $LAYER_ZIP
docker rm -f $CONTAINER

echo "Layer built successfully: $LAYER_ZIP"
