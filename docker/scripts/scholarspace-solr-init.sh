#!/bin/bash

set -e

# Checks for existence of the scholarspace core
if [ ! -d "/opt/solr/server/solr/mycores/scholarspace" ]
then
    # Replicated from the solr-create script
    echo "Creating scholarspace core"
    . /opt/docker-solr/scripts/run-initdb
    /opt/docker-solr/scripts/precreate-core scholarspace
    # ScholarSpace-specific setup
    echo "Disabling managed schema"
    mv /opt/solr/server/solr/mycores/scholarspace/conf/managed-schema /opt/solr/server/solr/mycores/scholarspace/conf/managed-schema.bak
    echo "Migrating configs"
    cp -r /opt/scholarspace/config/. /opt/solr/server/solr/mycores/scholarspace/conf
    echo "Starting Solr with new core..."
    exec /opt/docker-solr/scripts/solr-foreground
else
    echo "Core already exists! Starting Solr..."
    exec /opt/docker-solr/scripts/solr-foreground
fi
