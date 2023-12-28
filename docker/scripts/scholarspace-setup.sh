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

if [[ "$#" -eq 1 && $1 = "sidekiq" ]]
then  
  # Create sitemap cronjob, if necessary
  setuser scholarspace crontab -l > cron.tmp
  # cron.tmp won't be created if not cron jobs exist
  # if cron job exists, presume we've already created the sitemap job
  if [[ ! -e cron.tmp || ! -s cron.tmp ]]
  then
    # This isn't working in the docker volume, not sure why. It seems unable to execute the bundle command.
    echo "Creating cron job for sitemap"
    setuser scholarspace bundle exec whenever > cron.tmp && setuser scholarspace crontab cron.tmp
    rm cron.tmp
  fi
  echo "Starting sidekiq"
  exec /sbin/my_init -- bash -lc "bundle exec sidekiq --environment production"
else
echo "########## Creating DBs (prod) ########"
setuser scholarspace bundle exec rails db:create RAILS_ENV=production
echo "########## Migrating DBs (prod) #######"
setuser scholarspace bundle exec rails db:migrate RAILS_ENV=production
echo "####### Seeding DB (prod) #####"
setuser scholarspace bundle exec rails db:seed RAILS_ENV=production
echo "####### Precompiling assets (prod) ######"
setuser scholarspace bundle exec rails assets:precompile RAILS_ENV=production
echo "Starting Passenger..."
# Enable Nginx
rm -f /etc/service/nginx/down
exec /sbin/my_init
fi