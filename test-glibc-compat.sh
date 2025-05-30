#!/bin/bash

# Test script to verify glibc compatibility of binaries built with the container
# This script builds a test Rust project and checks glibc dependencies

set -e

IMAGE_NAME="${IMAGE_NAME:-manticoresearch/rust-min-libc}"
TAG="${TAG:-latest}"

echo "Testing glibc compatibility for ${IMAGE_NAME}:${TAG}"

# Create a temporary test project
TEST_DIR=$(mktemp -d)
cd "${TEST_DIR}"

# Create a simple Rust project with OpenSSL dependency
cat > Cargo.toml << 'EOF'
[package]
name = "glibc-test"
version = "0.1.0"
edition = "2021"

[dependencies]
openssl = "0.10"
reqwest = { version = "0.11", features = ["blocking"] }
EOF

mkdir src
cat > src/main.rs << 'EOF'
use std::process;

fn main() {
    println!("Testing glibc compatibility...");
    
    // Test OpenSSL
    let version = openssl::version::version();
    println!("OpenSSL version: {}", version);
    
    // Test a simple HTTP request to verify networking
    match reqwest::blocking::get("https://httpbin.org/get") {
        Ok(response) => {
            println!("HTTP request successful: {}", response.status());
        },
        Err(e) => {
            println!("HTTP request failed (this is OK for testing): {}", e);
        }
    }
    
    println!("All tests completed successfully!");
}
EOF

echo "Building test project with ${IMAGE_NAME}:${TAG}..."

# Build the project
docker run --rm \
    -v "${PWD}":/src \
    --user "$(id -u):$(id -g)" \
    "${IMAGE_NAME}:${TAG}" \
    build --release

BINARY_PATH="target/release/glibc-test"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "Binary built successfully!"
echo "Checking glibc dependencies..."

# Check glibc version requirements
echo "=== glibc Dependencies ==="
objdump -T "${BINARY_PATH}" | grep GLIBC | sed 's/.*GLIBC_\([.0-9]*\).*/\1/g' | sort -Vu | while read -r version; do
    echo "Requires glibc: ${version}"
done

echo ""
echo "=== Binary Information ==="
file "${BINARY_PATH}"
echo ""
echo "Size: $(du -h "${BINARY_PATH}" | cut -f1)"

echo ""
echo "=== Testing on different distributions ==="

# Test distributions (if available)
test_distros=("centos:7" "ubuntu:14.04" "ubuntu:16.04" "ubuntu:18.04" "debian:buster-slim")

for distro in "${test_distros[@]}"; do
    echo "Testing on ${distro}..."
    if docker run --rm -v "${PWD}/${BINARY_PATH}":/test-binary "${distro}" /test-binary 2>/dev/null; then
        echo "✓ ${distro}: SUCCESS"
    else
        echo "✗ ${distro}: FAILED"
    fi
done

echo ""
echo "Test completed! Binary location: ${TEST_DIR}/${BINARY_PATH}"
echo "To manually test: docker run --rm -v \"${TEST_DIR}/${BINARY_PATH}\":/test-binary <distro> /test-binary"