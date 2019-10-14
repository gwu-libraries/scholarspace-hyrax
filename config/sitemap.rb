# frozen_string_literal: true

Sitemap::Generator.instance.load(host: 'gwscholarspace-test2.wrlc.org', protocol: 'https') do
  path :root, priority: 1, change_frequency: 'weekly'
  path :search_catalog, priority: 1, change_frequency: 'weekly'

  read_group = Solrizer.solr_name('read_access_group', :symbol)
  GwWork.where(read_group => 'public').each do |f|
    literal Rails.application.routes.url_helpers.hyrax_gw_work_path(f, action: 'show'),
            priority: 1, change_frequency: 'weekly'
  end
  GwEtd.where(read_group => 'public').each do |f|
    literal Rails.application.routes.url_helpers.hyrax_gw_etds_path(f, action: 'show'),
            priority: 1, change_frequency: 'weekly'
  end
end
