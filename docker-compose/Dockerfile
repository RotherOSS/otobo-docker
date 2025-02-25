FROM alpine
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

# prepare env
RUN export CONTAINER_USER=logrotate && \
    export CONTAINER_GROUP=logrotate && \
    addgroup -g $CONTAINER_GID logrotate && \
    adduser -u $CONTAINER_UID -G logrotate -h /usr/bin/logrotate.d -s /bin/bash -S logrotate 

# install deps
RUN apk add --update \
	  bash \
      tzdata \
      logrotate \
      dcron

# generate simple logrotate config
RUN echo -e "/opt/otobo/var/log/otobo.log {\n\
        rotate 7\n\
        daily\n\
        compress\n\
        delaycompress\n\
        missingok\n\
        notifempty\n\
        create \n\
        su logrotate logrotate \n\
}\n" > /etc/logrotate.d/otobo

# set permissions
RUN chmod 0600 /etc/logrotate.d/otobo

# generate a wrapper bash script for crond
# this is to avoid 'setpgid: Operation not 
# permitted on Docker'
RUN echo -e "#!/bin/bash\n\
/usr/sbin/crond -f\n" > /cron.sh

# make script executable
RUN chmod a+x /cron.sh
    
# prepare logrotate dir
RUN mkdir -p /usr/bin/logrotate.d 

# check once per hour for logrotate
# TODO: remove the -f which forces logrotation for every run

# this is just for debugging purposes - run every 5 mins
#RUN echo "*/5 * * * * logrotate -f /etc/logrotate.d/otobo" >> /var/spool/cron/crontabs/root

# run once a day at midnight
RUN echo "0 0 * * * logrotate -f /etc/logrotate.d/otobo" >> /var/spool/cron/crontabs/root

# entrypoint command    
CMD /cron.sh






