FROM debian:bookworm-slim

RUN apt update && \
    apt upgrade -y && \
    apt install --no-install-recommends -y wget ca-certificates && \
    cd /usr/local/bin && \
    wget https://github.com/mvdan/sh/releases/download/v3.5.1/shfmt_v3.5.1_linux_amd64 && \
    mv shfmt_v3.5.1_linux_amd64 shfmt && \
    chmod +x shfmt

CMD ["/usr/local/bin/shfmt"]
