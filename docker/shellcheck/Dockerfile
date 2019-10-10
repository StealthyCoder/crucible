FROM debian:buster-slim

RUN apt update && \
    apt install -y shellcheck

RUN echo '#!/usr/bin/env bash\n\
for f in $(ls /srv/**)\n\
do\n\
echo $f;\n\
done\n\
' >> /srv/startup.sh
RUN cat /srv/startup.sh 


CMD ["/usr/bin/env", "bash", "/srv/startup.sh"]