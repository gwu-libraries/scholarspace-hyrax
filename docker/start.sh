echo "Starting Fedora"
fcrepo_wrapper -p 8984 --instance_directory /opt/scholarspace &

echo "Starting Solr"
solr_wrapper -d solr/config/ --solr_zip_path /opt/scholarspace/solr-6.2.0.zip  --instance_directory /opt/scholarspace/solr --no-checksum --collection_name hydra-development &

echo "Waiting for Fedora and Solr"
appdeps.py --wait-secs 150 --port-wait localhost:8984 --port-wait localhost:8983
if [ "$?" != "0" ]; then
    echo "Waiting for Fedora and Solr failed"
    exit 1
fi

# Run pending migrations
bundle exec rake db:migrate RAILS_ENV=development

echo "Starting Rails"
rails s -b 0.0.0.0
