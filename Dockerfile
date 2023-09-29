FROM phusion/passenger-ruby27:2.5.0

RUN apt update && apt install -y libpq-dev unzip clamav-daemon curl libreoffice libcurl4-openssl-dev ffmpeg gnupg2 libxml2 libxml2-dev wget

RUN apt update && apt build-dep -y imagemagick

RUN apt install -y checkinstall libwebp-dev libopenjp2-7-dev librsvg2-dev libde265-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /opt && \
   wget https://www.imagemagick.org/archive/releases/ImageMagick-7.1.1-12.tar.gz && \
   tar xzvf ImageMagick-7.1.1-12.tar.gz && \
   cd ImageMagick-7.1.1-12 && \
   ./configure --enable-shared --with-modules --with-gslib && \
   make && \
   make install && \
   ldconfig /usr/local/lib && \
   identify -version && \
   rm /opt/ImageMagick-7.1.1-12.tar.gz

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
    && mkdir -p /opt/scholarspace/certs \
    && mkdir -p /opt/scholarspace/scholarspace-tmp \
    && mkdir -p /opt/scholarspace/scholarspace-minter \
    && mkdir -p /opt/scholarspace/scholarspace-derivatives \
    && chmod 775 -R /opt/scholarspace/scholarspace-derivatives

WORKDIR /opt/scholarspace/scholarspace-hyrax

# Default ImageMagick configuration (to allow PDF's)
COPY ./docker/imagemagick/policy.xml /etc/ImageMagick-6/policy.xml

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
    && bundle lock --add-platform aarch64-linux \
    && bundle lock --add-platform x86_64-linux \
    && bundle install

# Copy app files
COPY . ./
# Create config files
RUN chmod +x docker/scripts/*.sh

# Script that creates the scholarspace user
CMD ["bash", "-l", "docker/scripts/scholarspace-setup.sh"]
