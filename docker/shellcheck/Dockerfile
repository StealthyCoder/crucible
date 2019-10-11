FROM debian:buster-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y shellcheck

RUN echo '#!/usr/bin/env bash\n\
for f in $(ls /srv/crucible/bash/**/*)\n\
do\n\
if [ -f $f ]; then shellcheck $f -x; fi\n\
done\n\
' >> /var/run/startup.sh


CMD ["/usr/bin/env", "bash", "/var/run/startup.sh"]