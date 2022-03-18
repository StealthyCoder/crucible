FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y shellcheck=0.5.0-3 && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*

RUN echo '#!/usr/bin/env bash\n\
shopt -s dotglob\n\
for f in $(ls /srv/crucible/bash/**/*)\n\
do\n\
if [ -f $f ]; then shellcheck $f -x -s bash; fi\n\
done\n\
for f in $(ls /srv/crucible-test/bash/**/*)\n\
do\n\
if [ -f $f ]; then shellcheck $f -x -s bash; fi\n\
done\n\
shellcheck /srv/crucible-test/.utils -s bash \n\
shellcheck /srv/.sh/*.sh -s bash\n\
' >> /var/run/startup.sh


CMD ["/usr/bin/env", "bash", "/var/run/startup.sh"]