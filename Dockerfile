FROM ubuntu:14.04
MAINTAINER Justin Littman <justinlittman@gwu.edu>

# Install apt-add-repository
RUN apt-get update && apt-get install -y \
    python-software-properties \
    software-properties-common
# Install Ruby
RUN apt-add-repository -y ppa:brightbox/ruby-ng
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    build-essential \
    ruby2.3 \
    ruby2.3-dev
# Install rails
RUN gem install rails -v 4.2.6
# Install Java 8
RUN apt-add-repository -y ppa:webupd8team/java
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get update && apt-get install -y \
    oracle-java8-installer \
    oracle-java8-set-default
# Install additional packages
RUN apt-get install -y \
    imagemagick \
    libreoffice \
    redis-server \
    unzip \
    libsqlite3-dev \
    python \
    python-pip
# Install scholarspace-sufia7
ADD . /opt/scholarspace/scholarspace-sufia7
# RUN mkdir -p /opt/scholarspace
# chown MYUSER:MYGROUP scholarspace
# RUN cd /opt/scholarspace
# RUN git clone https://github.com/gwu-libraries/scholarspace-sufia7.git
WORKDIR /opt/scholarspace/scholarspace-sufia7
RUN bundle install
RUN bundle exec rake db:migrate RAILS_ENV=development
# Startup script
ADD docker/start.sh /opt/scholarspace/
RUN chmod +x /opt/scholarspace/start.sh
# Install FITS
ENV FITS_VERSION 0.8.5
ADD http://projects.iq.harvard.edu/files/fits/files/fits-${FITS_VERSION}.zip /usr/local/bin/fits-${FITS_VERSION}.zip
WORKDIR /usr/local/bin
RUN unzip fits-${FITS_VERSION}.zip
WORKDIR fits-${FITS_VERSION}
RUN chmod a+x fits*.sh
# Prefetch Fedora jar
ENV FEDORA_VERSION 4.6.0
ADD https://github.com/fcrepo4/fcrepo4/releases/download/fcrepo-${FEDORA_VERSION}/fcrepo-webapp-${FEDORA_VERSION}-jetty-console.jar /opt/scholarspace/
ADD https://github.com/fcrepo4/fcrepo4/releases/download/fcrepo-${FEDORA_VERSION}/fcrepo-webapp-${FEDORA_VERSION}-jetty-console.jar.md5 /opt/scholarspace/
# Prefetch Solr Zip
ENV SOLR_VERSION 6.2.0
ADD https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.zip /opt/scholarspace/
ADD https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.zip.md5 /opt/scholarspace/
RUN mkdir /opt/scholarspace/solr
# Install appdeps
RUN pip install appdeps
EXPOSE 8984
EXPOSE 8983
EXPOSE 3000
WORKDIR /opt/scholarspace/scholarspace-sufia7
CMD ../start.sh
