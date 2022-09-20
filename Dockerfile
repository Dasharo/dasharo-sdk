FROM coreboot/coreboot-sdk:2021-09-23_b0d87f753c

MAINTAINER Michał Kopeć <michal.kopec@3mdeb.com>

USER root

COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN apt-get update && \
    apt-get install -y \
    gpg \
    libflashrom-dev \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://github.com/LongSoft/UEFITool/releases/download/A59/UEFIExtract_NE_A59_linux_x86_64.zip && \
    unzip UEFIExtract_NE_A59_linux_x86_64.zip && \
    mv UEFIExtract /usr/local/bin && \
    rm UEFIExtract_NE_A59_linux_x86_64.zip

# Build vboot tools. We should use a common revision of vboot tools there,
# which is known to support correctly all of the Dasharo platforms.
RUN git clone https://github.com/Dasharo/vboot.git \
      -b dasharo \
      --depth 1 && \
    cd vboot && \
    git checkout dc68f9f1b56d92f76026dca490e79493599ff4cf && \
    make && \
    make install && \
    rm -rf tests build

ENTRYPOINT ["/entrypoint.sh"]
