#!/bin/bash

set -e

for solr_core in $SOLR_CORE "$SOLR_CORE"_dev "$SOLR_CORE"_test; do

        if [ ! -d "/opt/solr/server/solr/mycores/${solr_core}" ]
    then
        # Replicated from the solr-create script
        echo "Creating ${solr_core} core"
        . /opt/docker-solr/scripts/run-initdb
        /opt/docker-solr/scripts/precreate-core $solr_core
        # ScholarSpace-specific setup
        echo "Disabling managed schema"
        mv /opt/solr/server/solr/mycores/${solr_core}/conf/managed-schema /opt/solr/server/solr/mycores/${solr_core}/conf/managed-schema.bak
        echo "Migrating configs"
        # Probably worth converting source path to an ENV variable?
        cp -r /opt/scholarspace/solr/conf /opt/solr/server/solr/mycores/${solr_core}
        echo "Starting Solr with new core..."
    else
        echo "Core ${solr_core} already exists!"
    fi
done

echo "Starting Solr ..."
exec /opt/docker-solr/scripts/solr-foreground
