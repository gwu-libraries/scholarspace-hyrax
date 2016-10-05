Sitemap::Generator.instance.load(host: 'example.com') do
  path :root, priority: 1, change_frequency: 'weekly'
  path :search_catalog, priority: 1, change_frequency: 'weekly'
  read_group = Solrizer.solr_name('read_access_group', :symbol)
  Work.where(read_group => 'public').each do |f|
    literal Rails.application.routes.url_helpers.curation_concerns_work_path(f),
            priority: 1, change_frequency: 'weekly'
  end
  Collection.where(read_group => 'public').each do |c|
    literal Rails.application.routes.url_helpers.collection_path(c),
            priority: 1, change_frequency: 'weekly'
  end
end
