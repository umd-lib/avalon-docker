#!/bin/bash

su - app
cd /home/app/avalon

if [ "$RAILS_GROUPS" != "aws" ]; then
    # sendmail needs this to work
    line=$(head -n 1 /etc/hosts)
    line2=$(echo $line | awk '{print $2}')
    echo "$line $line2.localdomain" >> /etc/hosts
    service sendmail start

    # batch ingest cronjob wouldn't autorun without this
    touch /var/spool/cron/crontabs/app

    chmod 0777 -R /masterfiles
    chown -R app /masterfiles

    BACKGROUND=yes QUEUE=* bundle exec rake resque:work
    BACKGROUND=yes bundle exec rake environment resque:scheduler
    RAILS_ENV=production bundle exec rake db:migrate
else
    if [ -z $SETTINGS__WORKER ]; then
        echo "SETTINGS__WORKER env not set: Webapp!"
        RAILS_ENV=production bundle exec rake db:migrate
    else
        echo "SETTINGS__WORKER env set: Worker!"
    fi
fi
