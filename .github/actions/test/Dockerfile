FROM debian:buster-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y wget

RUN echo '#!/usr/bin/env bash\n\
cd $GITHUB_WORKSPACE\n\
for f in $(ls $1/**/*)\n\
do\n\
if [ -f $f ]; then bash $f; fi\n\
done\n\
' >> /var/run/startup.sh


ENTRYPOINT ["/var/run/startup.sh"]
