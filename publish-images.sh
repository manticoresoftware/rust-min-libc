#!/bin/bash

# Publish script for manticoresearch/rust-min-libc Docker image
# This script builds and publishes multi-architecture images to Docker Hub

set -e

# Configuration
DOCKER_REPO="manticoresearch/rust-min-libc"
RUST_VERSION="1.86.0"
GLIBC_VERSION="2.15"

# Parse command line arguments
PUSH_LATEST=true
CUSTOM_TAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-latest)
            PUSH_LATEST=false
            shift
            ;;
        --tag)
            CUSTOM_TAG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --no-latest    Don't tag as 'latest'"
            echo "  --tag TAG      Use custom tag (in addition to version tags)"
            echo "  --help|-h      Show this help"
            echo ""
            echo "This script builds and publishes:"
            echo "  - ${DOCKER_REPO}:rust${RUST_VERSION}-glibc${GLIBC_VERSION}"
            echo "  - ${DOCKER_REPO}:rust${RUST_VERSION}"
            echo "  - ${DOCKER_REPO}:glibc${GLIBC_VERSION}"
            echo "  - ${DOCKER_REPO}:latest (unless --no-latest is specified)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Generate tags
FULL_VERSION_TAG="rust${RUST_VERSION}-glibc${GLIBC_VERSION}"
RUST_VERSION_TAG="rust${RUST_VERSION}"
GLIBC_VERSION_TAG="glibc${GLIBC_VERSION}"

echo "=== Publishing ${DOCKER_REPO} ==="
echo "Rust Version: ${RUST_VERSION}"
echo "glibc Version: ${GLIBC_VERSION}"
echo "Platforms: linux/amd64, linux/arm64"
echo ""

# Build tag arguments
TAG_ARGS=""
TAG_ARGS="${TAG_ARGS} --tag ${DOCKER_REPO}:${FULL_VERSION_TAG}"
TAG_ARGS="${TAG_ARGS} --tag ${DOCKER_REPO}:${RUST_VERSION_TAG}"
TAG_ARGS="${TAG_ARGS} --tag ${DOCKER_REPO}:${GLIBC_VERSION_TAG}"

if [ "$PUSH_LATEST" = true ]; then
    TAG_ARGS="${TAG_ARGS} --tag ${DOCKER_REPO}:latest"
fi

if [ -n "$CUSTOM_TAG" ]; then
    TAG_ARGS="${TAG_ARGS} --tag ${DOCKER_REPO}:${CUSTOM_TAG}"
fi

echo "Tags to be created:"
echo "  - ${DOCKER_REPO}:${FULL_VERSION_TAG}"
echo "  - ${DOCKER_REPO}:${RUST_VERSION_TAG}"
echo "  - ${DOCKER_REPO}:${GLIBC_VERSION_TAG}"
if [ "$PUSH_LATEST" = true ]; then
    echo "  - ${DOCKER_REPO}:latest"
fi
if [ -n "$CUSTOM_TAG" ]; then
    echo "  - ${DOCKER_REPO}:${CUSTOM_TAG}"
fi
echo ""

# Check if user is logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo "⚠️  You don't appear to be logged in to Docker Hub"
    echo "Please run: docker login"
    exit 1
fi

# Create and use buildx builder if it doesn't exist
if ! docker buildx ls | grep -q "multiarch-builder"; then
    echo "Creating multiarch-builder..."
    docker buildx create --name multiarch-builder --use
else
    echo "Using existing multiarch-builder..."
    docker buildx use multiarch-builder
fi

# Confirm before publishing
echo "Ready to build and publish to Docker Hub."
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "🚀 Building and pushing multi-architecture images..."

# Build and push
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --push \
    ${TAG_ARGS} \
    .

echo ""
echo "✅ Successfully published to Docker Hub!"
echo ""
echo "📦 Available tags:"
echo "  - docker pull ${DOCKER_REPO}:${FULL_VERSION_TAG}"
echo "  - docker pull ${DOCKER_REPO}:${RUST_VERSION_TAG}"
echo "  - docker pull ${DOCKER_REPO}:${GLIBC_VERSION_TAG}"
if [ "$PUSH_LATEST" = true ]; then
    echo "  - docker pull ${DOCKER_REPO}:latest"
fi
if [ -n "$CUSTOM_TAG" ]; then
    echo "  - docker pull ${DOCKER_REPO}:${CUSTOM_TAG}"
fi

echo ""
echo "🔗 Docker Hub: https://hub.docker.com/r/${DOCKER_REPO}"
echo ""
echo "📋 Usage example:"
echo "  docker run --rm -v \"\$(pwd)\":/src --user \"\$(id -u):\$(id -g)\" \\"
echo "    ${DOCKER_REPO}:${FULL_VERSION_TAG} build --release"