#!/bin/bash

# Multi-architecture build script for rust-min-libc Docker image
# This script builds the image for both amd64 and arm64 architectures
# Each architecture uses different library versions for optimal compatibility

set -e

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/manticoresoftware/rust-min-libc}"
PUSH="${PUSH:-false}"  # Set to true for publishing to registry

# Configuration
RUST_VERSION="1.86.0"

# Architecture-specific versions
AMD64_GLIBC_VERSION="2.17"
AMD64_OPENSSL_VERSION="1.0.1u"
ARM64_GLIBC_VERSION="2.28"
ARM64_OPENSSL_VERSION="1.1.1w"

# Generate architecture-specific tags
AMD64_TAG="amd64-rust${RUST_VERSION}-glibc${AMD64_GLIBC_VERSION}-openssl${AMD64_OPENSSL_VERSION}"
ARM64_TAG="aarch64-rust${RUST_VERSION}-glibc${ARM64_GLIBC_VERSION}-openssl${ARM64_OPENSSL_VERSION}"

echo "Building multi-architecture Docker image: ${IMAGE_NAME}"
echo ""
echo "📋 Architecture-Specific Tags:"
echo ""
echo "  AMD64 Configuration:"
echo "    - Rust: ${RUST_VERSION}"
echo "    - glibc: ${AMD64_GLIBC_VERSION}"
echo "    - OpenSSL: ${AMD64_OPENSSL_VERSION}"
echo "    - Tag: ${AMD64_TAG}"
echo ""
echo "  ARM64 Configuration:"
echo "    - Rust: ${RUST_VERSION}"
echo "    - glibc: ${ARM64_GLIBC_VERSION}"
echo "    - OpenSSL: ${ARM64_OPENSSL_VERSION}"
echo "    - Tag: ${ARM64_TAG}"
echo ""

if [ "$PUSH" = "true" ]; then
    echo "Images will be pushed to registry"
    echo "Checking authentication..."
    
    # Test authentication
    if ! docker login ghcr.io --password-stdin <<< "" 2>/dev/null; then
        echo "⚠️  Please log in to GitHub Container Registry:"
        echo "  docker login ghcr.io"
        echo "  OR with token: echo \$GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin"
        exit 1
    fi
    echo "✅ Authentication successful"
else
    echo "Images will be built locally only (no push)"
    echo "Set PUSH=true to publish to registry"
fi

# Create and use a new buildx builder instance
docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder

# Build arguments
BUILD_ARGS=""
TAG_ARGS=""
TAG_ARGS="${TAG_ARGS} --tag ${IMAGE_NAME}:${AMD64_TAG}"
TAG_ARGS="${TAG_ARGS} --tag ${IMAGE_NAME}:${ARM64_TAG}"

if [ "$PUSH" = "true" ]; then
    BUILD_ARGS="--push"
    PLATFORMS="linux/amd64,linux/arm64"
else
    echo "Note: For local multi-arch builds, images will be cached but not loaded to local Docker"
    echo "Use 'docker run --platform linux/amd64' or 'docker run --platform linux/arm64' to test"
    BUILD_ARGS=""
    PLATFORMS="linux/amd64,linux/arm64"
fi

echo "Building for platforms: ${PLATFORMS}"
echo ""

# Build for multiple platforms
docker buildx build \
  --platform ${PLATFORMS} \
  ${TAG_ARGS} \
  ${BUILD_ARGS} \
  .

echo ""
echo "✅ Multi-architecture build completed successfully!"
echo ""
echo "📦 Built Tags:"
echo "  - ${IMAGE_NAME}:${AMD64_TAG}"
echo "  - ${IMAGE_NAME}:${ARM64_TAG}"
echo ""

if [ "$PUSH" = "true" ]; then
    echo "🔍 To inspect architecture-specific details:"
    echo "  docker buildx imagetools inspect ${IMAGE_NAME}:${AMD64_TAG}"
    echo "  docker buildx imagetools inspect ${IMAGE_NAME}:${ARM64_TAG}"
    echo ""
    echo "🔗 GitHub Container Registry: https://github.com/manticoresoftware/manticore/pkgs/container/rust-min-libc"
fi

echo "📋 Usage examples:"
echo "  # Use specific architecture and versions:"
echo "  docker run --platform linux/amd64 --rm -v \"\$(pwd)\":/src \\"
echo "    ${IMAGE_NAME}:${AMD64_TAG} build --release"
echo ""
echo "  docker run --platform linux/arm64 --rm -v \"\$(pwd)\":/src \\"
echo "    ${IMAGE_NAME}:${ARM64_TAG} build --release"
echo ""
echo "💡 Note: Each architecture has different glibc/OpenSSL versions for optimal compatibility"
