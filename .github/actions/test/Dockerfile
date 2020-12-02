FROM debian:buster-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y wget

COPY  entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
