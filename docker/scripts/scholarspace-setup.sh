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
setuser scholarspace touch /opt/scholarspace/scholarspace-hyrax/log/production.log

# Set up nginx configuration, applying environment variables
echo "Configuring nginx"
if [[ "$SSL_ON" = true ]]; then
  envsubst < nginx_conf/scholarspace-ssl.conf > /etc/nginx/sites-enabled/scholarspace-ssl.conf
else
  envsubst < nginx_conf/scholarspace.conf > /etc/nginx/sites-enabled/scholarspace.conf
fi
# Add allow directives for GH pages IP ranges
cp nginx_conf/ghpages-cidr.conf /etc/nginx/conf.d/
# Remove default nginx site conf
rm /etc/nginx/sites-enabled/default

# Not sure if this step is necessary  
setuser scholarspace ruby2.7 -S passenger-config build-native-support

./docker/scripts/hyrax-config.sh

if [[ "$#" -eq 1 && $1 = "sidekiq" ]]; then  
  echo "Starting sidekiq"
  exec /sbin/my_init -- bash -lc "bundle exec sidekiq --environment production"
else

# Setting up sitemap regeneration schedule - configure in config/schedule.rb
# Default configuration is every day at 12:30 AM
echo "Preparing sitemap crontab"
setuser scholarspace bundle exec whenever --update-crontab

echo "Starting Passenger..."
# Enable Nginx
rm -f /etc/service/nginx/down
exec /sbin/my_init
fi
fi