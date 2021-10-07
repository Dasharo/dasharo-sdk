FROM coreboot/coreboot-sdk:2021-04-06_7014f8258e
MAINTAINER Michał Kopeć <michal.kopec@3mdeb.com>
USER root
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN apt update && apt install -y gpg
ENTRYPOINT ["/entrypoint.sh"]
