FROM debian:bookworm-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y shellcheck

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
