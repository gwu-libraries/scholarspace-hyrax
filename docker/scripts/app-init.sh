#!/bin/bash
# Contains Rake commands useful for initializing the app
# This script should be run as the scholarspace user, not root
# To run a container from the scholarspace image, do bash -lc scholarspace-hyrax-startup.sh
# Otherwise, the RVM environment will not be loaded
set -e
while [[ $# -gt 0 ]] && [[ $1 == "--"* ]] 
do 
    opt=$1;
    shift;
    case $opt in 
        "--" ) break;;
        "--load-schema")
            echo "Loading db schema" 
            bundle exec rake db:schema:load ;;
        "--run-migrations")
            echo "Running db migrations" 
            bundle exec rake db:migrate ;;
        "--precompile-assets")
            echo "Precompiling asses" 
            bundle exec rake assets:precompile ;;
        "--create-roles")
            echo "Creating ScholarSpace roles, if they do not exist" 
            bundle exec rake gwss:create_roles ;;
        "--create-admin-set")
            echo "Creating default admin set, if it does not exist" 
            bundle exec rake gwss:create_admin_set ;;
        "--create-secret")
            echo "Creating secret key"
            secret=$(bundle exec rake secret)
            echo "Key is $secret" ;;
         *) echo >&2 "Invalid option: $opt"; exit 1;;
    esac
done

