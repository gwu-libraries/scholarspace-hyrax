#!/bin/bash
# Should be executed when container starts, in order to map the scholarspace user to the user outside the container
# This is only really relevant for development, so a staged Dockerfile might be a better approach (down the road)
echo "Creating scholarspace user and group and setting permissions"
groupadd -r scholarspace --gid=${SCHOLARSPACE_GID:-999} \
     && useradd -r -g scholarspace -m --uid=${SCHOLARSPACE_UID:-999} scholarspace \
     && usermod -aG scholarspace www-data \
     && usermod -aG rvm scholarspace \
     && chown -R scholarspace:scholarspace /opt/scholarspace \
     && chmod 775 -R /opt/scholarspace/scholarspace-derivatives

# Create the log file here, so that it will be created with the correct permissions
# Otherwise, Passenger will create it as root
setuser scholarspace touch /opt/scholarspace/scholarspace-hyrax/log/${RAILS_ENV}.log

# Not sure if this step is necessary  
setuser scholarspace ruby2.7 -S passenger-config build-native-support

./docker/scripts/hyrax-config.sh

if [[ "$#" -eq 1 && $1 = "sidekiq" ]]
then
  echo "Starting sidekiq"
  exec /sbin/my_init -- bash -lc "bundle exec sidekiq"
fi
# Create sitemap cronjob, if necessary
setuser scholarspace crontab -l > cron.tmp
if [ ! -s cron.tmp ]
then
  # This isn't working in the docker volume, not sure why. It seems unable to execute the bundle command.
  #echo "Creating cron job for sitemap"
  #setuser scholarspace bundle exec whenever > cron.tmp && setuser scholarspace crontab cron.tmp
  rm cron.tmp
fi

echo "Starting Passenger..."
# Enable Nginx
rm -f /etc/service/nginx/down
exec /sbin/my_init
