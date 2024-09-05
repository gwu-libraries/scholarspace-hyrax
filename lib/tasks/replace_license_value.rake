require 'rake'

namespace :gwss do
    desc 'Replace license value for deprecated Europeana license'

    task :replace_license_value => :environment do 
        old_value = 'http://www.europeana.eu/portal/rights/rr-r.html'
        new_value = 'All rights reserved'

        # Since the text field (tesim) doesn't allow exact searching we do an additional filter just to be safe
        solr_results(old_value).each do |doc|
            work = ActiveFedora::Base.find(doc['id'])  # Retrieve the Fedora object
            work.license = work.license.map { |license_value| license_value == old_value ? new_value : license_value }      # Update the Fedora object
            work.save
        end
    end
end

def solr_results(old_value)
    # Retrieve paginated results if necessary for records with the old value in the license field
    params = {:q => "license_tesim:#{old_value}", fl:'id,license_tesim'}
    docs = ActiveFedora::SolrService.instance.conn.paginate(1, 1000, 'select', :params => params).dig('response', 'docs')
    p = 2
    while (next_page =  ActiveFedora::SolrService.instance.conn.paginate(p, 1000, 'select', :params => params).dig('response', 'docs')) != []
        docs += next_page
        p += 1
    end
    docs
end
