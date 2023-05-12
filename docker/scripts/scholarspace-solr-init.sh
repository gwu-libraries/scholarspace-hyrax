#!/bin/bash

set -e

# Checks for existence of the scholarspace core
if [ ! -d "/opt/solr/server/solr/mycores/${SOLR_CORE}" ]
then
    # Replicated from the solr-create script
    echo "Creating ${SOLR_CORE} core"
    . /opt/docker-solr/scripts/run-initdb
    /opt/docker-solr/scripts/precreate-core $SOLR_CORE
    # ScholarSpace-specific setup
    echo "Disabling managed schema"
    mv /opt/solr/server/solr/mycores/${SOLR_CORE}/conf/managed-schema /opt/solr/server/solr/mycores/${SOLR_CORE}/conf/managed-schema.bak
    echo "Migrating configs"
    cp -r /opt/scholarspace/config/. /opt/solr/server/solr/mycores/${SOLR_CORE}/conf
    echo "Starting Solr with new core..."
    exec /opt/docker-solr/scripts/solr-foreground
else
    echo "Core already exists! Starting Solr..."
    exec /opt/docker-solr/scripts/solr-foreground
fi
