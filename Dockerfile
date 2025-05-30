# Multi-architecture Dockerfile for Rust with minimal glibc targeting
# Supports amd64 and aarch64 with Ubuntu 12.04 glibc (2.15) for CentOS 7 compatibility

FROM debian:bookworm-20250428-slim AS builder

# Define build arguments for target architecture detection
ARG TARGETARCH
ARG TARGETPLATFORM

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl ca-certificates build-essential bison flex texinfo unzip \
        help2man gawk libtool-bin libncurses-dev python3 file \
    && groupadd rust -g 2000 && useradd -m -g rust -u 2000 rust

USER rust
WORKDIR /home/rust

# Build crosstool-ng
RUN curl http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.26.0.tar.xz | tar -xJf - \
    && cd crosstool-ng-1.26.0 \
    && ./configure --prefix=/home/rust/ct-ng \
    && make \
    && make install \
    && cd ..

# Create and customize configuration for minimal glibc (Ubuntu 12.04 compatible)
RUN case "${TARGETARCH}" in \
        "amd64") \
            export ARCH_TARGET="x86_64-ubuntu12.04-linux-gnu" && \
            /home/rust/ct-ng/bin/ct-ng x86_64-unknown-linux-gnu && \
            sed -i 's/CT_GLIBC_VERSION="[^"]*"/CT_GLIBC_VERSION="2.15"/' .config && \
            sed -i 's/CT_LINUX_VERSION="[^"]*"/CT_LINUX_VERSION="3.2.101"/' .config && \
            sed -i "s/CT_TARGET_ALIAS=\"[^\"]*\"/CT_TARGET_ALIAS=\"${ARCH_TARGET}\"/" .config; \
            ;; \
        "arm64") \
            export ARCH_TARGET="aarch64-ubuntu12.04-linux-gnu" && \
            /home/rust/ct-ng/bin/ct-ng aarch64-unknown-linux-gnu && \
            sed -i 's/CT_GLIBC_VERSION="[^"]*"/CT_GLIBC_VERSION="2.15"/' .config && \
            sed -i 's/CT_LINUX_VERSION="[^"]*"/CT_LINUX_VERSION="3.2.101"/' .config && \
            sed -i "s/CT_TARGET_ALIAS=\"[^\"]*\"/CT_TARGET_ALIAS=\"${ARCH_TARGET}\"/" .config; \
            ;; \
        *) \
            echo "Unsupported architecture: ${TARGETARCH}" && exit 1; \
            ;; \
    esac \
    && /home/rust/ct-ng/bin/ct-ng build

# Set architecture-specific variables and build OpenSSL
RUN case "${TARGETARCH}" in \
        "amd64") \
            export ARCH_TARGET="x86_64-ubuntu12.04-linux-gnu" && \
            export OPENSSL_CONFIG="linux-x86_64"; \
            ;; \
        "arm64") \
            export ARCH_TARGET="aarch64-ubuntu12.04-linux-gnu" && \
            export OPENSSL_CONFIG="linux-aarch64"; \
            ;; \
    esac \
    && chmod u+w /home/rust/x-tools/${ARCH_TARGET} \
    && chmod u+w /home/rust/x-tools/${ARCH_TARGET}/* \
    && curl --location https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz | tar -xzf - \
    && cd openssl-1.0.1u \
    && ./Configure ${OPENSSL_CONFIG} -fPIC no-shared --prefix=/home/rust/x-tools/${ARCH_TARGET} \
        --cross-compile-prefix=${ARCH_TARGET}- \
    && make CC=${ARCH_TARGET}-cc \
    && make install_sw

FROM rust:1.86.0-slim-bookworm

# Pass build arguments to final stage
ARG TARGETARCH
ARG TARGETPLATFORM

COPY --from=builder /home/rust/x-tools /usr/local/x-tools

# Create cargo configuration and environment setup
RUN groupadd rust -g 2000 \
    && useradd -m -g rust -u 2000 rust \
    && apt-get update \
    && apt-get install -y --no-install-recommends make libfindbin-libs-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up architecture-specific configuration
RUN case "${TARGETARCH}" in \
        "amd64") \
            export ARCH_TARGET="x86_64-ubuntu12.04-linux-gnu" && \
            export RUST_TARGET="x86_64-unknown-linux-gnu" && \
            echo "[target.${RUST_TARGET}]" > /usr/local/cargo/config.toml && \
            echo "linker = '${ARCH_TARGET}-cc'" >> /usr/local/cargo/config.toml && \
            echo "export PATH=/usr/local/x-tools/${ARCH_TARGET}/bin:\$PATH" >> /etc/environment && \
            echo "export OPENSSL_DIR=/usr/local/x-tools/${ARCH_TARGET}" >> /etc/environment && \
            echo "export ARCH_TARGET=${ARCH_TARGET}" >> /etc/environment && \
            echo "export RUST_TARGET=${RUST_TARGET}" >> /etc/environment; \
            ;; \
        "arm64") \
            export ARCH_TARGET="aarch64-ubuntu12.04-linux-gnu" && \
            export RUST_TARGET="aarch64-unknown-linux-gnu" && \
            echo "[target.${RUST_TARGET}]" > /usr/local/cargo/config.toml && \
            echo "linker = '${ARCH_TARGET}-cc'" >> /usr/local/cargo/config.toml && \
            echo "export PATH=/usr/local/x-tools/${ARCH_TARGET}/bin:\$PATH" >> /etc/environment && \
            echo "export OPENSSL_DIR=/usr/local/x-tools/${ARCH_TARGET}" >> /etc/environment && \
            echo "export ARCH_TARGET=${ARCH_TARGET}" >> /etc/environment && \
            echo "export RUST_TARGET=${RUST_TARGET}" >> /etc/environment; \
            ;; \
    esac

# Create architecture detection and information script
RUN echo '#!/bin/bash' > /usr/local/bin/show-build-info.sh \
    && echo 'source /etc/environment' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "=== Rust Minimal glibc Build Environment ==="' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "Target Architecture: ${ARCH_TARGET}"' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "Rust Target: ${RUST_TARGET}"' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "glibc Version: 2.15 (Ubuntu 12.04 / CentOS 7 compatible)"' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "OpenSSL: 1.0.1u (statically linked)"' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "Toolchain: ${PATH}"' >> /usr/local/bin/show-build-info.sh \
    && echo 'echo "====================================="' >> /usr/local/bin/show-build-info.sh \
    && chmod +x /usr/local/bin/show-build-info.sh

# Create wrapper script for cargo that sources environment
RUN echo '#!/bin/bash' > /usr/local/bin/cargo-wrapper.sh \
    && echo 'source /etc/environment' >> /usr/local/bin/cargo-wrapper.sh \
    && echo 'if [ "$1" = "info" ] || [ "$1" = "--info" ]; then' >> /usr/local/bin/cargo-wrapper.sh \
    && echo '    /usr/local/bin/show-build-info.sh' >> /usr/local/bin/cargo-wrapper.sh \
    && echo '    exit 0' >> /usr/local/bin/cargo-wrapper.sh \
    && echo 'fi' >> /usr/local/bin/cargo-wrapper.sh \
    && echo 'exec cargo "$@"' >> /usr/local/bin/cargo-wrapper.sh \
    && chmod +x /usr/local/bin/cargo-wrapper.sh

USER rust
WORKDIR /src

# Set environment for the rust user
RUN echo 'source /etc/environment' >> ~/.bashrc \
    && echo '/usr/local/bin/show-build-info.sh' >> ~/.bashrc

ENTRYPOINT ["/usr/local/bin/cargo-wrapper.sh"]