FROM coreboot/coreboot-sdk:2024-02-18_732134932b

USER root

COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    gpg \
    imagemagick \
    uuid-runtime \
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
    libxkbcommon-x11-0 \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://github.com/LongSoft/UEFITool/releases/download/A68/UEFIExtract_NE_A68_x64_linux.zip && \
    unzip UEFIExtract_NE_A68_x64_linux.zip && \
    mv uefiextract /usr/local/bin && \
    rm UEFIExtract_NE_A68_x64_linux.zip

RUN git clone https://github.com/coreboot/coreboot.git && \
    cd coreboot && \
    git checkout c1386ef6128922f49f93de5690ccd130a26eecf2 && \
    cd util/cbfstool && \
    make && \
    make install && \
    cd ../../ && \
    cd 3rdparty/vboot && \
    export USE_FLASHROM=0 && \
    make && \
    make install && \
    unset USE_FLASHROM && \
    rm -rf tests build

# Needed for vboot futility to sign images with VBOOT_CBFS_INTEGRATION
ENV CBFSTOOL=/usr/local/bin/cbfstool

ENTRYPOINT ["/entrypoint.sh"]
