FROM ghcr.io/gwu-libraries/scholarspace-base:latest

LABEL org.opencontainers.image.source=https://github.com/gwu-libraries/scholarspace-hyrax
LABEL org.opencontainers.image.description="Dockerized version of our Hyrax application, GW ScholarSpace"
LABEL org.opencontainers.image.licenses="MIT"

# Hyrax directories
RUN mkdir -p /opt/scholarspace/scholarspace-hyrax \ 
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
# Install dependencies and finalize Hyrax setup
# Running without development; installing as development seems to cause some issues
RUN gem install bundler -v 2.4.22 \
    && bundle lock --add-platform aarch64-linux \
    && bundle lock --add-platform x86_64-linux \
    && bundle install

# Copy app files
COPY . ./
# Create config files
RUN chmod +x docker/scripts/*.sh

# Script that creates the scholarspace user
CMD ["bash", "-l", "docker/scripts/scholarspace-setup.sh"]
