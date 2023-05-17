#!/bin/bash
# To be run at build time so that we can override with files from a mapped volume at runtime
set -e
# Copy config templates
cp config/initializers/hyrax.rb.template config/initializers/hyrax.rb
cp config/database.yml.template config/database.yml
cp config/solr.yml.template config/solr.yml
cp config/blacklight.yml.template config/blacklight.yml
cp config/fedora.yml.template config/fedora.yml
cp config/secrets.yml.template config/secrets.yml
# RAILS_ENV is one of production,development,test
# Should be passed in at build time: docker build --build-arg ENV_TYPE=development
cp config/environments/environment.rb.template config/environments/${RAILS_ENV:-production}.rb
