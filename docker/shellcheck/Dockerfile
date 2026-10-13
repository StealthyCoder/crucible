FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y shellcheck && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY shellcheck.sh /usr/local/bin/crucible-shellcheck

CMD ["/usr/local/bin/crucible-shellcheck"]
