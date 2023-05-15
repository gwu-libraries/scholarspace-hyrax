#!/bin/bash
# This script should be run as the scholarspace user, nor root
# To run a container from the scholarspace image, do bash -lc scholarspace-hyrax-init.sh
# Otherwise, the RVM environment will not be loaded
set -e
# DB migrations
echo "Running database migrations"
bundle exec rake db:migrate
# Create user roles --> if already created, will be ignored
echo "Creating ScholarSpace roles, if they do not exist"
bundle exec rake gwss:create_roles

echo "Creating default admin_set, if that does not exist"
bundle exec rake gwss:create_admin_set

echo "Precompiling assets"
bundle exec rake assets:precompile
