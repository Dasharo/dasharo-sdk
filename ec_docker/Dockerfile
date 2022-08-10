FROM debian:oldstable-20220125-slim

USER root

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        avr-libc \
        avrdude \
        clang-format \
        curl \
        gcc \
        gcc-avr \
        libc-dev \
        libhidapi-dev \
        libudev-dev \
        make \
        pkgconf \
        sdcc \
        xxd \
        ca-certificates \
        git && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#ENV RUSTUP_HOME=/usr/local/rustup \
#    CARGO_HOME=/usr/local/cargo \
#    PATH=/usr/local/cargo/bin:$PATH

#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init && \
#    chmod +x /tmp/rustup-init && \
#    /tmp/rustup-init -y --no-modify-path \
#        --default-toolchain nightly-2022-03-18 \
#        -t thumbv7em-none-eabihf \
#        -c llvm-tools-preview \
#        && \
#    rm /tmp/rustup-init

