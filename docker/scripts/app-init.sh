#!/bin/bash
# Contains Rake commands useful for initializing the app
# This script should be run as the scholarspace user, not root
# To run a container from the scholarspace image: docker exec -it --user scholarspace [app-container-name] bash -lc "docker/scripts/app-init.sh [script-options]"
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
            echo "Precompiling assets" 
            bundle exec rake assets:precompile ;;
        "--create-roles")
            echo "Creating ScholarSpace roles, if they do not exist" 
            bundle exec rake gwss:create_roles ;;
        # In using this command, prefix with an env variable assignment: admin_user=YOUR_EMAIL_ADDRESS
        "--add-admin-user")
            echo "Adding admin user to admin role"
            bundle exec rake gwss:add_admin_role ;;
        "--create-admin-set")
            echo "Creating default admin set" 
            #bundle exec rake gwss:create_admin_set ;;
            bundle exec rake hyrax:default_admin_set:create ;;
        "--create-secret")
            echo "Creating secret key"
            secret=$(bundle exec rake secret)
            echo "Key is $secret" ;;
        "--create-sitemap")
            echo "Generating sitemap"
            bundle exec rake gwss:sitemap_queue_generate ;;
        "--apply-content-blocks")
            echo "Applying content block changes"
            bundle exec rake gwss:apply_contentblock_changes ;;
         *) echo >&2 "Invalid option: $opt"; exit 1;;
    esac

    # Restart passenger after making any changes
    # Note that this will only work if running in development

    # If running in development via "rails s", with production delployed via passenger, this is not needed

    # if [ $RAILS_ENV = "development" ] 
    # then
    #     echo "Restarting Passenger"
    #     passenger-config restart-app /opt/scholarspace/scholarspace-hyrax
    # fi

done

