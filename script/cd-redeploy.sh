#!/bin/bash

# Change directory to the scholarspace folder
cd /opt/scholarspace/scholarspace-hyrax
# Stash any local changes
git stash
# Checkout master branch if not already on it
git checkout master
# Pull any changes
git pull
# Stop and remove containers
docker compose down
# Remove GHCR Images
echo "Deleting GHCR Docker iamges"
docker image rm $(docker images "ghcr.io/gwu-libraries/**" -q)
# Remove locally built images
echo "Deleting locally built Docker images"
docker image rm $(docker images "scholarspace-**" -q)
# Delete app volume
echo "Deleting app volume"
docker volume rm scholarspace-hyrax_app-hyrax
echo "Restarting Docker containers"
docker compose up -d
# If we don't sleep, Docker can't find the user
sleep 2
# Database migrations
echo "Running Database Migrations"
docker exec -i --user scholarspace $(docker ps --filter name=app -q) bash -lc "bundle exec rails db:migrate RAILS_ENV=production"
# Precompile Assets
echo "Precompiling assets"
docker exec -i --user scholarspace $(docker ps --filter name=app -q) bash -lc "bundle exec rails assets:precompile RAILS_ENV=production"
# Run rake task to apply any changes to contentblocks used on homepage/about/other main pages
echo "Applying contentblocks"
docker exec -i --user scholarspace $(docker ps --filter name=app -q) bash -lc "bundle exec rails gwss:apply_contentblock_changes RAILS_ENV=production"
# Restart Passenger
echo "Restarting Passenger"
docker exec -i --user scholarspace $(docker ps --filter name=app -q) bash -lc "passenger-config restart-app /"
