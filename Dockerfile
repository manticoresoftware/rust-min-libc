FROM debian:bookworm-20250428-slim AS builder

# Define build arguments for target architecture detection
ARG TARGETARCH
ARG TARGETPLATFORM

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates build-essential bison flex texinfo unzip help2man gawk libtool-bin libncurses-dev \
    && groupadd rust -g 2000 && useradd -m -g rust -u 2000 rust

USER rust
WORKDIR /home/rust

# Build crosstool-ng and toolchain - keep AMD64 exactly as original, add ARM64
RUN curl http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.27.0.tar.xz | tar -xJf - \
    && cd crosstool-ng-1.27.0 \
    && ./configure --prefix=/home/rust/ct-ng \
    && make -j8 \
    && make install \
    && cd .. \
		&& case "${TARGETARCH}" in \
        "amd64") \
            /home/rust/ct-ng/bin/ct-ng x86_64-ubuntu14.04-linux-gnu \
            && sed -i 's/CT_GLIBC_VERSION="[^"]*"/CT_GLIBC_VERSION="2.17"/' .config \
            && /home/rust/ct-ng/bin/ct-ng build -j8 \
            && chmod u+w /home/rust/x-tools/x86_64-ubuntu14.04-linux-gnu \
            && chmod u+w /home/rust/x-tools/x86_64-ubuntu14.04-linux-gnu/*; \
            ;; \
        "arm64") \
            /home/rust/ct-ng/bin/ct-ng aarch64-unknown-linux-gnu \
            && sed -i 's/CT_GLIBC_VERSION="[^"]*"/CT_GLIBC_VERSION="2.28"/' .config \
            && sed -i 's/CT_LINUX_VERSION="[^"]*"/CT_LINUX_VERSION="4.20.8"/' .config \
            && sed -i 's/CT_ARCH_64="[^"]*"/CT_ARCH_64="y"/' .config \
            && sed -i 's/CT_ARCH_ARCH="[^"]*"/CT_ARCH_ARCH="armv8-a"/' .config \
            && sed -i 's/CT_ARCH_arm_AVAILABLE="[^"]*"/CT_ARCH_arm_AVAILABLE="y"/' .config \
            && sed -i 's/CT_GDB_CROSS=y/CT_GDB_CROSS=n/' .config \
            && /home/rust/ct-ng/bin/ct-ng build -j8 \
            && chmod u+w /home/rust/x-tools/aarch64-unknown-linux-gnu \
            && chmod u+w /home/rust/x-tools/aarch64-unknown-linux-gnu/*; \
            ;; \
    esac

# Build OpenSSL - keep AMD64 exactly as original, add ARM64 equivalent
RUN case "${TARGETARCH}" in \
        "amd64") \
            curl --location https://www.openssl.org/source/old/1.0.1/openssl-1.0.1u.tar.gz | tar -xzf - \
            && cd openssl-1.0.1u \
            && export PATH=/home/rust/x-tools/x86_64-ubuntu14.04-linux-gnu/bin:$PATH \
            && ./config -fPIC no-shared --prefix=/home/rust/x-tools/x86_64-ubuntu14.04-linux-gnu \
            && make -j8 CC=x86_64-ubuntu14.04-linux-gnu-cc \
            && make install_sw; \
            ;; \
        "arm64") \
            curl --location https://www.openssl.org/source/openssl-1.1.1w.tar.gz | tar -xzf - \
            && cd openssl-1.1.1w \
            && export PATH=/home/rust/x-tools/aarch64-unknown-linux-gnu/bin:$PATH \
            && ./Configure linux-aarch64 -fPIC no-shared --prefix=/home/rust/x-tools/aarch64-unknown-linux-gnu \
                --cross-compile-prefix=aarch64-unknown-linux-gnu- \
            && make -j8 CC=aarch64-unknown-linux-gnu-cc \
            && make install_sw; \
            ;; \
    esac

FROM rust:1.86.0-slim-bookworm

# Pass build arguments to final stage
ARG TARGETARCH
ARG TARGETPLATFORM

COPY --from=builder /home/rust/x-tools /usr/local/x-tools

# Setup exactly as original for AMD64, equivalent for ARM64
RUN groupadd rust -g 2000 \
    && useradd -m -g rust -u 2000 rust \
    && apt-get update \
    && apt-get install -y --no-install-recommends make libfindbin-libs-perl

# Configure Cargo for the target architecture
RUN case "${TARGETARCH}" in \
        "amd64") \
            echo "[target.x86_64-unknown-linux-gnu]" > /usr/local/cargo/config.toml \
            && echo "linker = 'x86_64-ubuntu14.04-linux-gnu-cc'" >> /usr/local/cargo/config.toml \
            && echo "export OPENSSL_DIR=/usr/local/x-tools/x86_64-ubuntu14.04-linux-gnu" >> /etc/environment \
            && echo "export ARCH_TARGET=x86_64-ubuntu14.04-linux-gnu" >> /etc/environment \
            && echo "export RUST_TARGET=x86_64-unknown-linux-gnu" >> /etc/environment; \
            ;; \
        "arm64") \
            echo "[target.aarch64-unknown-linux-gnu]" > /usr/local/cargo/config.toml \
            && echo "linker = 'aarch64-unknown-linux-gnu-cc'" >> /usr/local/cargo/config.toml \
            && echo "export OPENSSL_DIR=/usr/local/x-tools/aarch64-unknown-linux-gnu" >> /etc/environment \
            && echo "export ARCH_TARGET=aarch64-unknown-linux-gnu" >> /etc/environment \
            && echo "export RUST_TARGET=aarch64-unknown-linux-gnu" >> /etc/environment; \
            ;; \
    esac

# Set PATH to include both toolchains (only the appropriate one will exist)
ENV PATH=/usr/local/x-tools/x86_64-ubuntu14.04-linux-gnu/bin:/usr/local/x-tools/aarch64-unknown-linux-gnu/bin:${PATH}

USER rust
WORKDIR /src

ENTRYPOINT ["cargo"]
