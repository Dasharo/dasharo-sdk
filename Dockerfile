# Generate the docker image for this file by running:
#
#   make coreboot-sdk

FROM debian:sid AS coreboot-sdk

# The coreboot Commit-ID to build the toolchain from.
ARG DOCKER_COMMIT
# The version of the coreboot sdk to use. Typically, this corresponds to the
# toolchain version. This is used to identify this docker image.
ARG SDK_VERSION
ARG CROSSGCC_PARAM

RUN \
	useradd -p locked -m coreboot && \
	apt-get update && \
	apt-get clean && \
	apt-get autoclean && \
	apt-get -y install --no-install-recommends \
		bash-completion \
		bc \
		bison \
		bsdextrautils \
		bzip2 \
		ca-certificates \
		ccache \
		cmake \
		cscope \
		curl \
		device-tree-compiler \
		dh-autoreconf \
		diffutils \
		exuberant-ctags \
		flex \
		g++ \
		gawk \
		gcc \
		git \
		golang \
		gpg \
		graphviz \
		imagemagick \
		lcov \
		less \
		libcapture-tiny-perl \
		libcrypto++-dev \
		libcurl4-openssl-dev \
		libdatetime-perl \
		libelf-dev \
		libfreetype-dev \
		libftdi1-dev \
		libglib2.0-dev \
		libgmp-dev \
		libgpiod-dev \
		libjaylink-dev \
		liblzma-dev \
		libncurses-dev \
		libnss3-dev \
		libpci-dev \
		libreadline-dev \
		libssl-dev \
		libtimedate-perl \
		libusb-1.0-0-dev \
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
		libxml2-dev \
		libyaml-dev \
		m4 \
		make \
		msitools \
		neovim \
		openssh-client \
		openssl \
		parted \
		patch \
		pbzip2 \
		pkg-config \
		python-is-python3 \
		python3 \
		qemu-system-arm \
		qemu-system-misc \
		qemu-system-ppc \
		qemu-system-x86 \
		rsync \
		sharutils \
		shellcheck \
		unifont \
		unzip \
		uuid-dev \
		uuid-runtime \
		vim-common \
		wget \
		xz-utils \
		zlib1g-dev \
    libxkbcommon-x11-0 \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
	cd /tmp && \
	git clone https://review.coreboot.org/coreboot && \
	cd coreboot && \
	git checkout ${DOCKER_COMMIT}; \
	if echo ${CROSSGCC_PARAM} | grep -q ^all; then \
		make -C /tmp/coreboot/util/crossgcc/ build_clang \
			BUILD_LANGUAGES=c CPUS=$(nproc) DEST=/opt/xgcc; \
	fi; \
	make -C /tmp/coreboot/util/crossgcc/ ${CROSSGCC_PARAM} \
		BUILD_LANGUAGES=c CPUS=$(nproc) DEST=/opt/xgcc && \
	rm -rf /tmp/coreboot

# We need the latest smmstoretool changes to be included,
# not part of the release yet
RUN \
	  cd /tmp && \
    git clone https://github.com/coreboot/coreboot.git  && \
    cd coreboot && \
    git checkout -f 24.08 && \
    make -C util/cbfstool && \
    make -C util/cbfstool install && \
    export USE_FLASHROM=0 && \
    make -C 3rdparty/vboot && \
    make -C 3rdparty/vboot install && \
    mkdir /vboot && \
    cp -r 3rdparty/vboot/scripts /vboot/ && \
    unset USE_FLASHROM && \
    make -C util/smmstoretool && \
    make -C util/smmstoretool install && \
    make -C util/ifdtool && \
    make -C util/ifdtool install && \
    cd .. && \
    rm -rf coreboot

# nvmtool is needed for DCU
RUN cd /tmp && \
    git clone https://review.coreboot.org/coreboot.git && \
    cd coreboot && \
    git fetch https://review.coreboot.org/coreboot refs/changes/29/67129/5 && \
    git checkout -b change-67129 FETCH_HEAD && \
    cd util/nvmtool && \
    make && \
    cp nvm /usr/local/bin/nvm && \
    cd ../../.. && \
    rm -rf coreboot

RUN wget https://github.com/LongSoft/UEFITool/releases/download/A68/UEFIExtract_NE_A68_x64_linux.zip && \
    unzip UEFIExtract_NE_A68_x64_linux.zip && \
    mv uefiextract /usr/local/bin && \
    rm UEFIExtract_NE_A68_x64_linux.zip

RUN git clone https://github.com/wolfSSL/wolfssl.git -b v5.7.0-stable --depth=1 && \
    cd wolfssl && \
    ./autogen.sh && \
    ./configure --libdir /lib/x86_64-linux-gnu/ && \
    make
RUN cd wolfssl && make install V=1 > /wolfssl_install.log
RUN cd .. && \
    rm -rf wolfssl

FROM debian:stable-slim AS dasharo-sdk

COPY --from=coreboot-sdk /opt/xgcc /opt/xgcc
COPY --from=coreboot-sdk /usr/local/bin/cbfstool /usr/local/bin/cbfstool
COPY --from=coreboot-sdk /usr/local/bin/fmaptool /usr/local/bin/fmaptool
COPY --from=coreboot-sdk /usr/local/bin/rmodtool /usr/local/bin/rmodtool
COPY --from=coreboot-sdk /usr/local/bin/ifwitool /usr/local/bin/ifwitool
COPY --from=coreboot-sdk /usr/local/bin/ifittool /usr/local/bin/ifittool
COPY --from=coreboot-sdk /usr/local/bin/cbfs-compression-tool /usr/local/bin/cbfs-compression-tool
COPY --from=coreboot-sdk /usr/local/bin/elogtool /usr/local/bin/elogtool
COPY --from=coreboot-sdk /usr/local/bin/cse_fpt /usr/local/bin/cse_fpt
COPY --from=coreboot-sdk /usr/local/bin/cse_serger /usr/local/bin/cse_serger
COPY --from=coreboot-sdk /vboot /vboot
COPY --from=coreboot-sdk /usr/share/vboot /usr/share/vboot
COPY --from=coreboot-sdk /usr/local/bin/smmstoretool /usr/local/bin/smmstoretool
COPY --from=coreboot-sdk /usr/local/bin/ifdtool /usr/local/bin/ifdtool
COPY --from=coreboot-sdk /usr/local/bin/nvm /usr/local/bin/nvm
COPY --from=coreboot-sdk /usr/local/bin/uefiextract /usr/local/bin/uefiextract
COPY --from=coreboot-sdk /usr/local/bin/wolfssl-config /usr/local/bin/
COPY --from=coreboot-sdk /usr/local/share/doc/wolfssl /usr/local/share/doc/wolfssl
COPY --from=coreboot-sdk /lib/x86_64-linux-gnu/libwolfssl.so.42.1.0 /lib/x86_64-linux-gnu/
COPY --from=coreboot-sdk /lib/x86_64-linux-gnu/libwolfssl.so.42 /lib/x86_64-linux-gnu/
COPY --from=coreboot-sdk /lib/x86_64-linux-gnu/libwolfssl.so /lib/x86_64-linux-gnu/
COPY --from=coreboot-sdk /lib/x86_64-linux-gnu/libwolfssl.la /lib/x86_64-linux-gnu/
COPY --from=coreboot-sdk /lib/x86_64-linux-gnu/pkgconfig/wolfssl.pc /lib/x86_64-linux-gnu/pkgconfig/
COPY --from=coreboot-sdk /usr/local/include/wolfssl /usr/local/include/wolfssl

RUN useradd -p locked -m coreboot
RUN mkdir /home/coreboot/.ccache && \
	chown coreboot:coreboot /home/coreboot/.ccache && \
	mkdir /home/coreboot/cb_build && \
	chown coreboot:coreboot /home/coreboot/cb_build && \
	echo "export PATH=$PATH:/opt/xgcc/bin" >> /home/coreboot/.bashrc && \
	echo "export SDK_VERSION=${SDK_VERSION}" >> /home/coreboot/.bashrc && \
	echo "export SDK_COMMIT=${DOCKER_COMMIT}" >> /home/coreboot/.bashrc

# Needed for vboot futility to sign images with VBOOT_CBFS_INTEGRATION
ENV CBFSTOOL=/usr/local/bin/cbfstool

USER coreboot
