FROM coreboot/coreboot-sdk:2024-02-18_732134932b AS coreboot-sdk

USER root
# We need the latest smmstoretool changes to be included,
# not part of the release yet
RUN \
		cd /tmp && \
		git clone https://github.com/coreboot/coreboot.git  && \
		cd coreboot && \
		git checkout -f ${DOCKER_COMMIT} && \
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
RUN cd wolfssl && make install
RUN cd .. && \
		rm -rf wolfssl

FROM debian:stable-slim AS intermediate

COPY --from=coreboot-sdk /opt/xgcc /opt/xgcc

# Cleanup unecessary xgcc targets
RUN \
	rm -rf /opt/xgcc/bin/clang-* \
		/opt/xgcc/bin/llvm-* \
		/opt/xgcc/bin/aarch64-* \
		/opt/xgcc/bin/riscv64-* \
		/opt/xgcc/bin/powerpc64-* \
		/opt/xgcc/bin/nds32le-* \
		/opt/xgcc/bin/arm-eabi-* \
		/opt/xgcc/lib/gcc/nds32le-elf \
		/opt/xgcc/lib/gcc/powerpc64-linux-gnu \
		/opt/xgcc/lib/gcc/aarch64-elf \
		/opt/xgcc/lib/gcc/riscv64-elf \
		/opt/xgcc/lib/gcc/arm-eabi \
		/opt/xgcc/lib/clang \
		/opt/xgcc/lib/libclang* \
		/opt/xgcc/lib/libLLVM*


FROM debian:stable-slim AS dasharo-sdk

COPY --from=intermediate /opt/xgcc /opt/xgcc
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
COPY --from=coreboot-sdk /usr/bin/futility /usr/bin/futility
COPY --from=coreboot-sdk /usr/bin/dumpRSAPublicKey /usr/bin/dumpRSAPublicKey

RUN for prog in dump_fmap dump_kernel_config gbb_utility vbutil_firmware vbutil_kernel vbutil_key vbutil_keyblock; do \
    ln -sf /usr/bin/futility "/usr/bin/$prog"; done

RUN \
	useradd -p locked -m coreboot && \
	apt-get update && \
	apt-get clean && \
	apt-get autoclean && \
	apt-get -y install --no-install-recommends \
		libcrypto++-dev \
		make \
		binutils \
		ca-certificates \
		clang \
		g++ \
		gcc \
		git \
		guilt \
		imagemagick \
		libc6 \
		libc6-dev \
		libncurses-dev \
		libnss3-dev \
		libssl-dev \
		liblzma-dev \
		lld \
		llvm \
		pkg-config \
		python-is-python3 \
		python3 \
		unzip \
		uuid-dev \
		uuid-runtime \
		&& \
		apt-get clean && \
		rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /home/coreboot/.ccache && \
	chown coreboot:coreboot /home/coreboot/.ccache && \
	mkdir /home/coreboot/cb_build && \
	chown coreboot:coreboot /home/coreboot/cb_build && \
	echo "export PATH=$PATH:/opt/xgcc/bin" >> /home/coreboot/.bashrc && \
	echo "export SDK_VERSION=${SDK_VERSION}" >> /home/coreboot/.bashrc && \
	echo "export SDK_COMMIT=${DOCKER_COMMIT}" >> /home/coreboot/.bashrc

# Needed for vboot futility to sign images with VBOOT_CBFS_INTEGRATION
ENV CBFSTOOL=/usr/local/bin/cbfstool

ENV PATH=$PATH:/opt/xgcc/bin
USER coreboot
VOLUME /home/coreboot/.ccache
