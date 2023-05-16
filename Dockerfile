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

# Create scholarspace user/group with ID's (from .env with docker-compose, 999 as default)
# Assign group memberships for Apache & scholarspace users
RUN groupadd -r scholarspace --gid=${SCHOLARSPACE_GID:-999} \
     && useradd -r -g scholarspace -m --uid=${SCHOLARSPACE_UID:-999} scholarspace \
     && usermod -aG scholarspace www-data \
     && usermod -aG rvm scholarspace 

# Hyrax directories
RUN mkdir /opt/install \
    && mkdir /opt/xsendfile \
    && mkdir -p /opt/scholarspace/scholarspace-hyrax \ 
    && mkdir /opt/scholarspace/scholarspace-tmp \
    && mkdir /opt/scholarspace/scholarspace-minter \
    && mkdir /opt/scholarspace/scholarspace-derivatives \
    && chown www-data:www-data /opt/xsendfile \
    && chown -R scholarspace:scholarspace /opt/scholarspace \
    && chmod 775 -R /opt/scholarspace/scholarspace-derivatives

# Nginx configuration
COPY nginx_conf/scholarspace.conf /etc/nginx/sites-enabled/scholarspace.conf
# Enable Nginx with new configuration
RUN rm /etc/nginx/sites-enabled/default && rm -f /etc/service/nginx/down

# install app dependencies as scholarspace user

WORKDIR /opt/scholarspace/scholarspace-hyrax

# Switch to bash shell so that we can use the source command
SHELL ["/bin/bash", "-c"]

COPY ./docker/scripts/rvm-wrapper.sh ./docker/scripts/rvm-wrapper.sh
# Replace the existing ruby2.7 wrapper with one that points to our version of Ruby
RUN source ./docker/scripts/rvm-wrapper.sh && rm /usr/bin/ruby2.7 \
    && create_rvm_wrapper_script ruby2.7 ruby-2.7.3 ruby
# Compile it for Passenger
RUN ruby2.7 -S passenger-config build-native-support \
        && setuser scholarspace ruby2.7 -S passenger-config build-native-support

# Copy Gemfile separately, so that we don't have to rebuild this stage every time we change another file
COPY --chown=scholarspace:scholarspace Gemfile Gemfile.lock ./

USER scholarspace
# Used to create the correct file in config/environments 
ARG RAILS_ENV

# Install dependencies and finalize Hyrax setup
RUN gem install bundler \
    && bundle install --deployment 

# Copy app files
COPY --chown=scholarspace:scholarspace . ./
# Create config files
RUN chmod +x docker/scripts/*.sh \
    && bash -lc "docker/scripts/scholarspace-hyrax-setup.sh"

# This seems inelegant, but the my_init script requires root permissions
USER root

CMD ["/sbin/my_init"]