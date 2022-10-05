FROM debian:bookworm-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y wget ca-certificates

COPY  entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
