# Docker Rust Minimum glibc Target (Multi-Architecture)

[![Build and Push](https://github.com/manticoresoftware/manticore/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/manticoresoftware/manticore/actions/workflows/build-and-push.yml)

This Docker image compiles Rust applications targeting minimal glibc for maximum portability across Linux distributions. 
It supports both **amd64** and **aarch64** architectures with optimized library versions for each platform.

## 🐳 GitHub Container Registry

**Repository**: [ghcr.io/manticoresoftware/rust-min-libc](https://github.com/manticoresoftware/manticore/pkgs/container/rust-min-libc)

### Available Tags

**Architecture-Specific Tags (Full Version Details):**
- `ghcr.io/manticoresoftware/rust-min-libc:amd64-rust1.86.0-glibc2.27-openssl1.1.1k` - AMD64 with all versions
- `ghcr.io/manticoresoftware/rust-min-libc:aarch64-rust1.86.0-glibc2.27-openssl1.1.1k` - ARM64 with all versions

## Key Features

- **Multi-Architecture Support**: Builds for amd64 (x86_64) and aarch64 (ARM64) with optimized configurations
- **Minimal glibc**: Architecture-optimized glibc versions for maximum compatibility
- **Enterprise Compatible**: Perfect compatibility with CentOS 7+ and RHEL 7+
- **Static OpenSSL**: Architecture-specific OpenSSL versions statically linked
- **Automatic Detection**: Automatically detects and configures for the target platform

## Architecture Details

| Architecture | Target Triple | glibc | OpenSSL | Compatibility |
|--------------|---------------|-------|---------|---------------|
| **amd64** | `x86_64-ubuntu14.04-linux-gnu` | **2.27** | **1.1.1k** | Ubuntu 18.04+, CentOS 8+ |
| **arm64** | `aarch64-unknown-linux-gnu` | **2.27** | **1.1.1k** | Ubuntu 18.04+, CentOS 8+ |

> **Why different versions?** ARM64 support was added to glibc in version 2.18, while x86_64 has been supported since much earlier versions. This allows us to use the absolute minimum glibc version for each architecture.

## Usage

### Quick Start
Build a Rust project (automatically detects architecture):
```shell
docker container run --rm --volume "$(pwd)":/src \
    --user "$(id --user):$(id --group)" \
    ghcr.io/manticoresoftware/rust-min-libc build --release
```

### Architecture-Specific Builds
```shell
# Build for x86_64 with minimal glibc 2.27
docker run --platform linux/amd64 --rm -v "$(pwd)":/src \
    ghcr.io/manticoresoftware/rust-min-libc build --release

# Build for arm64 with minimal glibc 2.27  
docker run --platform linux/arm64 --rm -v "$(pwd)":/src \
    ghcr.io/manticoresoftware/rust-min-libc build --release
```

### Show Build Information
```shell
docker run --rm ghcr.io/manticoresoftware/rust-min-libc --version
```

### Using Specific Tags
```shell
# Use architecture-specific tags with full version details
docker run --platform linux/amd64 --rm -v "$(pwd)":/src \
    ghcr.io/manticoresoftware/rust-min-libc:amd64-rust1.86.0-glibc2.27-openssl1.1.1k build --release

docker run --platform linux/arm64 --rm -v "$(pwd)":/src \
    ghcr.io/manticoresoftware/rust-min-libc:aarch64-rust1.86.0-glibc2.27-openssl1.1.1w build --release
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

### GitHub Actions (Recommended)

The repository includes a **high-performance GitHub Actions workflow** that builds images using native runners:

**🚀 Native Builds:**
- **AMD64**: Built on `ubuntu-24.04` (native x86_64)
- **ARM64**: Built on `ubuntu-24.04-arm` (native aarch64)
- **Parallel**: Both architectures build simultaneously for maximum speed
- **No Emulation**: ~10x faster than traditional cross-compilation

**Automatic Triggers:**
- ✅ Push to `main` or `master` branch
- ✅ Git tags starting with `v*`
- ✅ Manual trigger via GitHub Actions UI

**Manual Trigger:**
1. Go to **Actions** tab in your GitHub repository
2. Select **"Build and Push Multi-Architecture Docker Images"**
3. Click **"Run workflow"**
4. Choose branch and push option

### Local Development
```shell
# Build locally for testing
./build-multiarch.sh

# Build and publish to GitHub Container Registry (manual)
PUSH=true ./build-multiarch.sh
```

**Note:** Using GitHub Actions is recommended as it handles authentication and permissions automatically.

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
docker run --platform linux/amd64 --rm -v "$(pwd)":/src ghcr.io/manticoresoftware/rust-min-libc build --release
docker run --platform linux/arm64 --rm -v "$(pwd)":/src ghcr.io/manticoresoftware/rust-min-libc build --release
```

### Custom Cargo Configuration
The image includes a pre-configured `cargo` config for cross-compilation, but you can override it:

```shell
docker run --rm -v "$(pwd)":/src -v "$(pwd)/.cargo":/usr/local/cargo ghcr.io/manticoresoftware/rust-min-libc build --release
```

## Credits
* [crosstool-ng](https://crosstool-ng.github.io/)
* [A one-liner I was too lazy to come up with](https://stackoverflow.com/questions/3436008/how-to-determine-version-of-glibc-glibcxx-binary-will-depend-on)