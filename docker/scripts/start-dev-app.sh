#!/bin/bash

set -e

echo "########## Creating DBs (dev/test) ########"
bundle exec rails db:create 
echo "########## Migrating DBs (dev/test) #######"
bundle exec rails db:migrate 
echo "########## Creating default roles (dev/test) #######"
bundle exec rails gwss:create_roles 
bundle exec rails gwss:add_admin_role
echo "######### Creating default admin set (dev/test) #######"
bundle exec rails hyrax:default_admin_set:create
echo "######## Applying content blocks (dev/test) #######"
bundle exec rails gwss:apply_contentblock_changes
echo "####### Creating sitemap queue ########"
bundle exec rake gwss:sitemap_queue_generate
echo "######## starting dev server on port 3000 ######"
bundle exec rails s -b 0.0.0.0