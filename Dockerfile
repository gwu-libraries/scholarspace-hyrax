FROM phusion/passenger-ruby27:latest

RUN apt update && apt install -y libpq-dev unzip clamav-daemon curl imagemagick libreoffice libcurl4-openssl-dev apache2 apache2-dev ffmpeg gnupg2 libxml2 libxml2-dev wget

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
    && mkdir /opt/scholarspace \ 
    && mkdir /opt/scholarspace/scholarspace-tmp \
    && mkdir /opt/scholarspace/scholarspace-minter \
    && mkdir /opt/scholarspace/scholarspace-derivatives
    && chown www-data:www-data /opt/xsendfile \
    && chown -R scholarspace:scholarspace /opt/scholarspace \
    && chmod 775 -R /opt/scholarspace/scholarspace-derivatives


# FITS install
WORKDIR /usr/local/bin

RUN wget https://github.com/harvard-lts/fits/releases/download/1.5.0/fits-1.5.0.zip \
    && unzip fits-1.5.0.zip -d fits-1.5.0 \
    && rm fits-1.5.0.zip \
    && chmod a+x fits-1.5.0/fits*.sh

COPY --chown=scholarspace:scholarspace . /opt/scholarspace/scholarspace-hyrax

USER scholarspace

WORKDIR /opt/scholarspace/scholarspace-hyrax

# Used to create the correct file in config/environments
ARG ENV_TYPE

# Install dependencies and finalize Hyrax setup
RUN gem install bundler \
    && bundle install --deployment \
    && chmod +x docker/scripts/scholarspace-hyrax-init.sh \
    && bash -lc "docker/scripts/scholarspace-hyrax-init.sh"

ENTRYPOINT ["/bin/bash"]
