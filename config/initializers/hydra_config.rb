# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

Hydra.configure do |config|
  # This specifies the solr field names of permissions-related fields.
  # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
  # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
  #
  # config.permissions.discover.group       = ActiveFedora::SolrQueryBuilder.solr_name("discover_access_group", :symbol)
  # config.permissions.discover.individual  = ActiveFedora::SolrQueryBuilder.solr_name("discover_access_person", :symbol)
  # config.permissions.read.group           = ActiveFedora::SolrQueryBuilder.solr_name("read_access_group", :symbol)
  # config.permissions.read.individual      = ActiveFedora::SolrQueryBuilder.solr_name("read_access_person", :symbol)
  # config.permissions.edit.group           = ActiveFedora::SolrQueryBuilder.solr_name("edit_access_group", :symbol)
  # config.permissions.edit.individual      = ActiveFedora::SolrQueryBuilder.solr_name("edit_access_person", :symbol)
  #
  # config.permissions.embargo.release_date  = ActiveFedora::SolrQueryBuilder.solr_name("embargo_release_date", :stored_sortable, type: :date)
  # config.permissions.lease.expiration_date = ActiveFedora::SolrQueryBuilder.solr_name("lease_expiration_date", :stored_sortable, type: :date)
  #
  #
  # Specify the user model
  # config.user_model = 'User'
  #
  # DWK set this to comply with deprecation warning:
  # DEPRECATION WARNING: You must set 'config.user_key_field = Devise.authentication_keys.first' 
  # in your config/initializer/hydra_config.rb file. The default value will be
  # removed inihydra-access-controls 12. (called from user_key_field at
  # /opt/scholarspace/scholarspace-hyrax/vendor/bundle/ruby/2.3.0/gems/hydra-access-controls-10.5.0/lib/hydra/config.rb:39)
  config.user_key_field = Devise.authentication_keys.first
end
