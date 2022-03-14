FROM debian:buster-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y vim=2:8.1.0875-5 wget=1.20.1-1.1 ca-certificates=20200601~deb10u2 && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*


CMD ["/usr/bin/env", "bash"]