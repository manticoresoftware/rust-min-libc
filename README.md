t# Docker Rust Minimum glibc Target (Multi-Architecture)

This Docker image compiles Rust applications targeting minimal glibc for maximum portability across Linux distributions. 
It supports both **amd64** and **aarch64** architectures with optimized library versions for each platform.

## 🐳 Docker Hub

**Repository**: [manticoresearch/rust-min-libc](https://hub.docker.com/r/manticoresearch/rust-min-libc)

### Available Tags

**Architecture-Specific Tags (Full Version Details):**
- `manticoresearch/rust-min-libc:amd64-rust1.86.0-glibc2.17-openssl1.0.1u` - AMD64 with all versions
- `manticoresearch/rust-min-libc:aarch64-rust1.86.0-glibc2.28-openssl1.1.1w` - ARM64 with all versions

## Key Features

- **Multi-Architecture Support**: Builds for amd64 (x86_64) and aarch64 (ARM64) with optimized configurations
- **Minimal glibc**: Architecture-optimized glibc versions for maximum compatibility
- **Enterprise Compatible**: Perfect compatibility with CentOS 7+ and RHEL 7+
- **Static OpenSSL**: Architecture-specific OpenSSL versions statically linked
- **Automatic Detection**: Automatically detects and configures for the target platform

## Architecture Details

| Architecture | Target Triple | glibc | OpenSSL | Compatibility |
|--------------|---------------|-------|---------|---------------|
| **amd64** | `x86_64-ubuntu14.04-linux-gnu` | **2.17** | **1.0.1u** | Ubuntu 12.04+, CentOS 7+ |
| **arm64** | `aarch64-unknown-linux-gnu` | **2.28** | **1.1.1w** | Ubuntu 18.04+, CentOS 8+ |

> **Why different versions?** ARM64 support was added to glibc in version 2.18, while x86_64 has been supported since much earlier versions. This allows us to use the absolute minimum glibc version for each architecture.

## Usage

### Quick Start
Build a Rust project (automatically detects architecture):
```shell
docker container run --rm --volume "$(pwd)":/src \
    --user "$(id --user):$(id --group)" \
    manticoresearch/rust-min-libc build --release
```

### Architecture-Specific Builds
```shell
# Build for x86_64 with minimal glibc 2.17
docker run --platform linux/amd64 --rm -v "$(pwd)":/src \
    manticoresearch/rust-min-libc build --release

# Build for arm64 with minimal glibc 2.28  
docker run --platform linux/arm64 --rm -v "$(pwd)":/src \
    manticoresearch/rust-min-libc build --release
```

### Show Build Information
```shell
docker run --rm manticoresearch/rust-min-libc --version
```

### Using Specific Tags
```shell
# Use architecture-specific tags with full version details
docker run --platform linux/amd64 --rm -v "$(pwd)":/src \
    manticoresearch/rust-min-libc:amd64-rust1.86.0-glibc2.17-openssl1.0.1u build --release

docker run --platform linux/arm64 --rm -v "$(pwd)":/src \
    manticoresearch/rust-min-libc:aarch64-rust1.86.0-glibc2.28-openssl1.1.1w build --release
```

## Compatibility Testing

Check glibc dependencies of your binary:
```shell
objdump -T BINARY | grep GLIBC | sed 's/.*GLIBC_\([.0-9]*\).*/\1/g' | sort -Vu
```

### Verified Compatible Distributions
The image has been tested and verified to work on:

**Enterprise/LTS Distributions:**
- CentOS 7+ (primary target)
- RHEL 7+
- Ubuntu 12.04+ (LTS versions)
- Debian 8+ (Jessie and newer)

**Modern Distributions:**
- Ubuntu 14.04, 16.04, 18.04, 20.04, 22.04, 24.04
- Debian: buster, bullseye, bookworm
- Rocky Linux 8, 9
- openSUSE Leap, Tumbleweed
- Alpine Linux (with glibc)

## Development and Building

### Local Development
```shell
# Build locally for testing
./build-multiarch.sh

# Build and publish to Docker Hub
PUSH=true ./build-multiarch.sh
```

## Environment Variables

The container automatically sets up these environment variables:

- `ARCH_TARGET`: Target toolchain (e.g., `x86_64-ubuntu12.04-linux-gnu`)
- `RUST_TARGET`: Rust target triple (e.g., `x86_64-unknown-linux-gnu`)
- `OPENSSL_DIR`: Path to statically linked OpenSSL
- `PATH`: Includes the cross-compilation toolchain

## Advanced Usage

### Cross-Compilation
The image automatically handles cross-compilation. When running on Apple Silicon (M1/M2), 
it can build x86_64 binaries, and vice versa:

```shell
# Force specific platform
docker run --platform linux/amd64 --rm -v "$(pwd)":/src rust-min-libc build --release
docker run --platform linux/arm64 --rm -v "$(pwd)":/src rust-min-libc build --release
```

### Custom Cargo Configuration
The image includes a pre-configured `cargo` config for cross-compilation, but you can override it:

```shell
docker run --rm -v "$(pwd)":/src -v "$(pwd)/.cargo":/usr/local/cargo rust-min-libc build --release
```

## Credits
* [crosstool-ng](https://crosstool-ng.github.io/)
* [A one-liner I was too lazy to come up with](https://stackoverflow.com/questions/3436008/how-to-determine-version-of-glibc-glibcxx-binary-will-depend-on)
