# Docker Rust Minimum glibc Target (Multi-Architecture)

This Docker image compiles Rust applications targeting minimal glibc for maximum portability across Linux distributions. 
It supports both **amd64** and **aarch64** architectures and uses a toolchain built with crosstool-ng that targets 
Ubuntu 12.04's glibc (version 2.15) for excellent CentOS 7 compatibility.

## Key Features

- **Multi-Architecture Support**: Automatically builds for amd64 (x86_64) and aarch64 (ARM64)
- **Minimal glibc**: Targets glibc 2.15 (Ubuntu 12.04) for maximum compatibility
- **CentOS 7 Compatible**: Works on CentOS 7 and other older distributions
- **Static OpenSSL**: Includes OpenSSL 1.0.1u statically linked
- **Automatic Detection**: Automatically detects and configures for the target platform

## Usage

### Quick Start
Build a Rust project (automatically detects architecture):
```shell
docker container run --rm --volume "$(pwd)":/src \
    --user "$(id --user):$(id --group)" \
    rust-min-libc build --release
```

### Show Build Information
```shell
docker run --rm rust-min-libc info
```

### Multi-Architecture Build
Build the Docker image for both architectures:
```shell
./build-multiarch.sh
```

### Test glibc Compatibility
```shell
./test-glibc-compat.sh
```

## Building the Image

### Local Build (Current Architecture)
```shell
docker build -t rust-min-libc .
```

### Multi-Architecture Build
```shell
# Build for both amd64 and arm64
./build-multiarch.sh

# Or manually:
docker buildx build --platform linux/amd64,linux/arm64 -t rust-min-libc .
```

## Architecture Support

| Architecture | Target Triple | Toolchain | glibc Version |
|--------------|---------------|-----------|---------------|
| amd64 (x86_64) | x86_64-unknown-linux-gnu | x86_64-ubuntu12.04-linux-gnu | 2.15 |
| aarch64 (ARM64) | aarch64-unknown-linux-gnu | aarch64-ubuntu12.04-linux-gnu | 2.15 |

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
