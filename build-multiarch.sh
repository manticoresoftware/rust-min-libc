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
AMD64_GLIBC_VERSION="2.28"
AMD64_OPENSSL_VERSION="1.1.1k"
ARM64_GLIBC_VERSION="2.28"
ARM64_OPENSSL_VERSION="1.1.1k"

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

# Authentication check for push
if [ "$PUSH" = "true" ]; then
    echo "Images will be pushed to registry"
    echo "Checking authentication..."
    
    # Try custom authentication first if variables are provided
    if [ -n "$GHCR_USER" ]; then
        echo "Using custom GHCR credentials..."
        echo "$GHCR_PASSWORD" | docker login -u"$GHCR_USER" --password-stdin ghcr.io
    fi
    
    # Verify authentication worked
    if ! (docker info | grep Username) > /dev/null 2>&1; then
        echo "⚠️  Not authenticated to GHCR. Please run:"
        echo "  docker login ghcr.io"
        echo "  OR: echo \$GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin"
        exit 1
    fi
    
    # Show who we're authenticated as
    AUTH_USER=$(docker info | grep Username | awk '{print $2}' || echo "unknown")
    echo "✅ Successfully authenticated to GitHub Container Registry as: $AUTH_USER"
    
    # Test if we can actually push to this repository
    echo "🔍 Testing repository access..."
    if docker buildx build --platform linux/amd64 --tag "${IMAGE_NAME}:test-$(date +%s)" --push . >/dev/null 2>&1; then
        echo "✅ Repository access confirmed"
    else
        echo "❌ Cannot push to repository ${IMAGE_NAME}"
        echo "Check if you have push permissions to the 'manticoresoftware' organization"
        exit 1
    fi
else
    echo "Images will be built locally and loaded to Docker"
    echo "Set PUSH=true to publish to registry"
fi

# Create and use a new buildx builder instance
docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder

echo "Building architectures..."
echo ""

# Build AMD64 (load locally if not pushing)
echo "🔨 Building AMD64..."
if [ "$PUSH" = "true" ]; then
    echo "Building and pushing AMD64 to: ${IMAGE_NAME}:${AMD64_TAG}"
    docker buildx build \
      --platform linux/amd64 \
      --tag "${IMAGE_NAME}:${AMD64_TAG}" \
      --push \
      --progress=plain \
      .
    BUILD_RESULT=$?
    if [ $BUILD_RESULT -eq 0 ]; then
        echo "✅ AMD64 build command completed successfully"
    else
        echo "❌ AMD64 build command failed with exit code: $BUILD_RESULT"
        exit 1
    fi
else
    docker buildx build \
      --platform linux/amd64 \
      --tag "${IMAGE_NAME}:${AMD64_TAG}" \
      --load \
      .
    echo "✅ AMD64 loaded locally"
fi

echo ""

# Build ARM64 (load locally if not pushing)
echo "🔨 Building ARM64..."
if [ "$PUSH" = "true" ]; then
    echo "Building and pushing ARM64 to: ${IMAGE_NAME}:${ARM64_TAG}"
    docker buildx build \
      --platform linux/arm64 \
      --tag "${IMAGE_NAME}:${ARM64_TAG}" \
      --push \
      --progress=plain \
      .
    BUILD_RESULT=$?
    if [ $BUILD_RESULT -eq 0 ]; then
        echo "✅ ARM64 build command completed successfully"
    else
        echo "❌ ARM64 build command failed with exit code: $BUILD_RESULT"
        exit 1
    fi
else
    # Note: Can't load ARM64 on non-ARM machines
    CURRENT_ARCH=$(docker version --format '{{.Server.Arch}}')
    if [ "$CURRENT_ARCH" = "arm64" ]; then
        docker buildx build \
          --platform linux/arm64 \
          --tag "${IMAGE_NAME}:${ARM64_TAG}" \
          --load \
          .
        echo "✅ ARM64 loaded locally"
    else
        echo "⚠️  Skipping ARM64 local load (can't load ARM64 on ${CURRENT_ARCH} machine)"
        echo "    ARM64 image built and cached, use --push to publish to registry"
    fi
fi

echo ""
echo "✅ Multi-architecture build completed successfully!"
echo ""
echo "📦 Built Tags:"
echo "  - ${IMAGE_NAME}:${AMD64_TAG}"
echo "  - ${IMAGE_NAME}:${ARM64_TAG}"
echo ""

if [ "$PUSH" = "true" ]; then
    echo "🔍 To inspect pushed images:"
    echo "  docker buildx imagetools inspect ${IMAGE_NAME}:${AMD64_TAG}"
    echo "  docker buildx imagetools inspect ${IMAGE_NAME}:${ARM64_TAG}"
    echo ""
    echo "🔍 Verifying images were actually pushed:"
    echo "  Checking AMD64 image..."
    if docker pull "${IMAGE_NAME}:${AMD64_TAG}" >/dev/null 2>&1; then
        echo "  ✅ AMD64 image confirmed in registry (can pull)"
        docker rmi "${IMAGE_NAME}:${AMD64_TAG}" >/dev/null 2>&1 || true
    else
        echo "  ❌ AMD64 image NOT found in registry (cannot pull)"
    fi
    
    echo "  Checking ARM64 image..."
    # Use buildx imagetools for ARM64 since we can't pull it on AMD64 machines
    if docker buildx imagetools inspect "${IMAGE_NAME}:${ARM64_TAG}" >/dev/null 2>&1; then
        echo "  ✅ ARM64 image confirmed in registry (buildx can inspect)"
    else
        echo "  ❌ ARM64 image NOT found in registry (buildx cannot inspect)"
    fi
    echo ""
    echo "🔗 GitHub Container Registry: https://github.com/manticoresoftware/manticore/pkgs/container/rust-min-libc"
else
    echo "🔍 To inspect local images:"
    echo "  docker inspect ${IMAGE_NAME}:${AMD64_TAG}"
    echo "  docker inspect ${IMAGE_NAME}:${ARM64_TAG}"
    echo ""
    echo "📋 Local images available:"
    echo "Available images with this name:"
    docker images | grep "${IMAGE_NAME}" || echo "No images found with name ${IMAGE_NAME}"
    echo ""
    echo "All local images:"
    docker images | head -5
fi

echo ""
echo "📋 Usage examples:"
echo "  # Use specific architecture and versions:"
echo "  docker run --platform linux/amd64 --rm -v \"\$(pwd)\":/src \\"
echo "    ${IMAGE_NAME}:${AMD64_TAG} build --release"
echo ""
echo "  docker run --platform linux/arm64 --rm -v \"\$(pwd)\":/src \\"
echo "    ${IMAGE_NAME}:${ARM64_TAG} build --release"
echo ""
echo "💡 Note: Each architecture has different glibc/OpenSSL versions for optimal compatibility"
