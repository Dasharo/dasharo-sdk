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

# We need the latest smmstoretool changes to be included,
# not part of the release yet
RUN git clone https://github.com/coreboot/coreboot.git  && \
    cd coreboot && \
    git checkout 05bb053e6356b30bfa2ae27d0b38e592e4c58111 && \
    cd util/cbfstool && \
    make && \
    make install && \
    cd ../../ && \
    cd 3rdparty/vboot && \
    export USE_FLASHROM=0 && \
    make && \
    make install && \
    unset USE_FLASHROM && \
    cd ../../ && \
    cd util/smmstoretool && \
    make && \
    make install && \
    rm -rf tests build

RUN git clone https://github.com/wolfSSL/wolfssl.git -b v5.7.0-stable --depth=1 && \
    cd wolfssl && \
    ./autogen.sh && \
    ./configure --libdir /lib/x86_64-linux-gnu/ && \
    make && \
    make install

# ifdtool is needed for DCU
RUN cd coreboot && \
    make -C util/ifdtool && \
    make -C util/ifdtool install

# nvmtool is needed for DCU
RUN rm -rf coreboot && \
    git clone https://review.coreboot.org/coreboot.git && \
    cd coreboot && \
    git fetch https://review.coreboot.org/coreboot refs/changes/29/67129/5 && \
    git checkout -b change-67129 FETCH_HEAD && \
    cd util/nvmtool && \
    make && \
    cp nvm /usr/local/bin/nvm


# Needed for vboot futility to sign images with VBOOT_CBFS_INTEGRATION
ENV CBFSTOOL=/usr/local/bin/cbfstool

ENTRYPOINT ["/entrypoint.sh"]
