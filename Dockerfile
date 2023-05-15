FROM coreboot/coreboot-sdk:2021-09-23_b0d87f753c

MAINTAINER Michał Kopeć <michal.kopec@3mdeb.com>

USER root

COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN apt-get update && \
    apt-get install -y \
    gpg \
    unzip \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-sync1 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://github.com/LongSoft/UEFITool/releases/download/A59/UEFIExtract_NE_A59_linux_x86_64.zip && \
    unzip UEFIExtract_NE_A59_linux_x86_64.zip && \
    mv UEFIExtract /usr/local/bin && \
    rm UEFIExtract_NE_A59_linux_x86_64.zip

RUN git clone https://github.com/coreboot/coreboot.git \
      -b master \
      --depth 1 && \
    cd coreboot && \
    git checkout 497fea7d673b201b044a70baeb93ef04e175fa58 && \
    cd util/cbfstool && \
    make && \
    make install

# Build vboot tools. We should use a common revision of vboot tools there,
# which is known to support correctly all of the Dasharo platforms.
RUN git clone https://github.com/Dasharo/vboot.git \
      -b master \
      --depth 1 && \
    cd vboot && \
    git checkout 22134690d7ced7b2ea824b71b597bb73586d99c6 && \
    export USE_FLASHROM=0 && \
    make && \
    make install && \
    unset USE_FLASHROM && \
    rm -rf tests build

# Needed for vboot futility to sign images with VBOOT_CBFS_INTEGRATION
ENV CBFSTOOL=/usr/local/bin/cbfstool

ENTRYPOINT ["/entrypoint.sh"]
