#!/bin/bash

# sendmail needs this to work
line=$(head -n 1 /etc/hosts)
line2=$(echo $line | awk '{print $2}')
echo "$line $line2.localdomain" >> /etc/hosts
service sendmail start

# batch ingest cronjob wouldn't autorun without this
touch /var/spool/cron/crontabs/app

chmod 0777 -R /masterfiles
chown -R app /masterfiles

chmod 0777 -R /streamfiles
chown -R app /streamfiles

cd /home/app/avalon
su app

# Source the environment varaibles set in config file
if [ -f /run/secrets/ap-secrets ]; then
    . /run/secrets/ap-secrets
fi

BACKGROUND=yes QUEUE=* bundle exec rake resque:work
BACKGROUND=yes bundle exec rake environment resque:scheduler
RAILS_ENV=production bundle exec rake db:migrate
exit