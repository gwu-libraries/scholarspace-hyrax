#!/bin/bash
ENVIRONMENT=$1
if [ $# -eq 0 ]; then
    echo -e "ERROR: no environment argument [production|test|development] provided" 
    exit 1
fi

if [ $ENVIRONMENT != "production" ] && [ $ENVIRONMENT != "test" ] && [ $ENVIRONMENT != "development" ]; then
    echo -e "ERROR: environment argument must be either [production|test|development] most likely this will be development for local machines and production otherwise" 
    exit 1
fi

bundle exec rake sufia:stats:user_stats RAILS_ENV=$ENVIRONMENT
