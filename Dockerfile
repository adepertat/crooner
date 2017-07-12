FROM docker:17.05

LABEL maintainer="Albéric de Pertat <alberic@depertat.net>" \
      version="2" \
      description="Run Docker stacks through cron"

RUN apk add --no-cache bash

COPY crooner /sbin/crooner
RUN rm /etc/crontabs/root && ln -s /etc/crontab /etc/crontabs/root

ENTRYPOINT ["crooner"]
CMD ["start"]
