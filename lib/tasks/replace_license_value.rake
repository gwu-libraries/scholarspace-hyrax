require 'rake'

namespace :gwss do
    desc 'Replace license value for deprecated Europeana license'

    task :replace_license_value => :environment do 
        old_value = 'http://www.europeana.eu/portal/rights/rr-r.html'
        new_value = 'All rights reserved'
        num_changed = 0
        # Since the text field (tesim) doesn't allow exact searching we do an additional filter just to be safe
        solr_results(old_value).each do |doc|
            work = ActiveFedora::Base.find(doc['id'])  # Retrieve the Fedora object
            work.license = work.license.map { |license_value| license_value == old_value ? new_value : license_value }      # Update the Fedora object
            work.save
            num_changed += 1
        end
        puts "#{num_changed} documents have been updated to have the license value #{new_value}"
    end
end

def solr_results(old_value)
    # Retrieve paginated results if necessary for records with the old value in the license field
    params = {:q => "license_tesim:\"http://www.europeana.eu/portal/rights/rr-r.html\"", fl:'id,license_tesim'}
    r = ActiveFedora::SolrService.instance.conn.paginate(1, 1000, 'select', :params => params)
    puts "Found #{r['response']['numFound']} documents with the old license value #{old_value}."
    if r['response']['numFound'] == 0
        return []
    end
    puts "Updating docs..." 
    docs = r.dig('response', 'docs')
    page_num = 2
    while (next_page =  ActiveFedora::SolrService.instance.conn.paginate(page_num, 1000, 'select', :params => params).dig('response', 'docs')) != []
        docs += next_page
        page_num += 1
    end
    docs
end
