FROM coreboot/coreboot-sdk:2021-09-23_b0d87f753c

MAINTAINER Michał Kopeć <michal.kopec@3mdeb.com>

USER root

COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN apt-get update && \
    apt-get install -y \
    gpg \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://github.com/LongSoft/UEFITool/releases/download/A59/UEFIExtract_NE_A59_linux_x86_64.zip && \
    unzip UEFIExtract_NE_A59_linux_x86_64.zip && \
    mv UEFIExtract /usr/local/bin && \
    rm UEFIExtract_NE_A59_linux_x86_64.zip

ENTRYPOINT ["/entrypoint.sh"]
