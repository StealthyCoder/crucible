FROM debian:buster-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y shellcheck

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