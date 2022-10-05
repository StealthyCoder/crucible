FROM debian:bookworm-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends wget ca-certificates && \
    cd /usr/local/bin && \
    wget https://github.com/mvdan/sh/releases/download/v3.5.1/shfmt_v3.5.1_linux_amd64 && \
    mv shfmt_v3.5.1_linux_amd64 shfmt && \
    chmod +x shfmt

COPY  entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
