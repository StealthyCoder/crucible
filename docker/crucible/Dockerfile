FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y vim wget ca-certificates && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*


CMD ["/usr/bin/env", "bash"]
