FROM debian:bookworm-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends wget ca-certificates binutils xxd netcat-openbsd libdigest-sha-perl

COPY  entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
