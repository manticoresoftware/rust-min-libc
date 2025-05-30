#!/bin/bash

# Multi-architecture build script for rust-min-libc Docker image
# This script builds the image for both amd64 and arm64 architectures

set -e

IMAGE_NAME="${IMAGE_NAME:-manticoresearch/rust-min-libc}"
TAG="${TAG:-latest}"

echo "Building multi-architecture Docker image: ${IMAGE_NAME}:${TAG}"
echo "This will build for both amd64 and arm64 platforms..."

# Create and use a new buildx builder instance
docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "${IMAGE_NAME}:${TAG}" \
  --push \
  .

echo "Multi-architecture build completed successfully!"
echo "Image: ${IMAGE_NAME}:${TAG}"
echo "Platforms: linux/amd64, linux/arm64"
echo ""
echo "To test the image:"
echo "  # For current platform:"
echo "  docker run --rm -v \"\$(pwd)\":/src ${IMAGE_NAME}:${TAG} info"
echo ""
echo "  # To build a Rust project:"
echo "  docker run --rm -v \"\$(pwd)\":/src --user \"\$(id -u):\$(id -g)\" ${IMAGE_NAME}:${TAG} build --release"