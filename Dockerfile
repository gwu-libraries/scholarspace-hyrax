FROM phusion/passenger-ruby27:2.5.0

RUN apt update && apt install -y libpq-dev unzip clamav-daemon curl imagemagick libreoffice libcurl4-openssl-dev ffmpeg gnupg2 libxml2 libxml2-dev wget

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# FITS install
WORKDIR /usr/local/bin

RUN wget https://github.com/harvard-lts/fits/releases/download/1.5.0/fits-1.5.0.zip \
    && unzip fits-1.5.0.zip -d fits-1.5.0 \
    && rm fits-1.5.0.zip \
    && chmod a+x fits-1.5.0/fits*.sh
    
# Uninstall Ruby version from image and install our version
# bash -lc is necessary per the configuration of the base image 
RUN bash -lc "rvm remove ruby-2.7.7 && rvm install ruby-2.7.3 && gem install rails -v 5.2.7 -N"

# Hyrax directories
RUN mkdir -p /opt/scholarspace/scholarspace-hyrax \ 
    && mkdir /opt/scholarspace/scholarspace-tmp \
    && mkdir /opt/scholarspace/scholarspace-minter \
    && mkdir /opt/scholarspace/scholarspace-derivatives \
    && chmod 775 -R /opt/scholarspace/scholarspace-derivatives

# Nginx configuration
COPY nginx_conf/scholarspace.conf /etc/nginx/sites-enabled/scholarspace.conf
# Enable Nginx with new configuration
RUN rm /etc/nginx/sites-enabled/default && rm -f /etc/service/nginx/down


WORKDIR /opt/scholarspace/scholarspace-hyrax
# Switch to bash shell so that we can use the source command
SHELL ["/bin/bash", "-c"]

COPY ./docker/scripts/rvm-wrapper.sh ./docker/scripts/rvm-wrapper.sh
# Replace the existing ruby2.7 wrapper with one that points to our version of Ruby
RUN source ./docker/scripts/rvm-wrapper.sh && rm /usr/bin/ruby2.7 \
    && create_rvm_wrapper_script ruby2.7 ruby-2.7.3 ruby
# Compile it for Passenger
RUN ruby2.7 -S passenger-config build-native-support 

# Copy Gemfile separately, so that we don't have to rebuild this stage every time we change another file
COPY Gemfile Gemfile.lock ./
# Used to create the correct file in config/environments 
ARG RAILS_ENV
# Install dependencies and finalize Hyrax setup
# Running without development; installing as development seems to cause some issues
RUN gem install bundler \
    && bundle install --without development --deployment 

# Copy app files
COPY . ./
# Create config files
RUN chmod +x docker/scripts/*.sh \
    && bash -lc "docker/scripts/hyrax-config.sh"

# Script that creates the scholarspace user
CMD ["bash", "-l", "docker/scripts/scholarspace-setup.sh"]