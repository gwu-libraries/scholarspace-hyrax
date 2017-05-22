require 'fileutils'
require 'json'

namespace :gwss  do
  # adding a logger since it got removed from our gemset
  #def logger
  #  Rails.logger
  #end

  desc "Queues a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    SitemapRegenerateJob.perform_later
  end

  desc "batch ingest of ETDs"
  task :ingest_etds, [:manifest_file, :batchfiles_path, :ingest_id] => :environment do |t, args|
    begin
      # Reference GwWork to work around circular dependency
      # problem that would be caused by referencing GwEtd first
      # See articles such as http://neethack.com/2015/04/rails-circular-dependency/
      GwWork
      puts "starting batch ingest"
      manifest_file = args.manifest_file
      puts manifest_file
      batchfiles_path = args.batchfiles_path
      ingest_id = args.ingest_id 
      if File.exist?(manifest_file)
        mf = File.read(manifest_file)
        manifest_json = JSON.parse(mf)
        noid_list = ingest(manifest_json, batchfiles_path)
        # generate_ingest_report(noid_list, investigation_id) 
      else
        puts "file didn't exist - no ingest"
      end
    end
  end

  def ingest(json, batchfiles_path)
    noid_list=[]
    # We expect an array [] of json objects
    json.each do |metadata|
      begin
        next if metadata.empty?
        file_attributes = read_metadata(metadata)
        gwe = GwEtd.new
        gwe.apply_depositor_metadata('kerchner@gwu.edu')
#        gwe.attributes = file_attributes
        gwe.attributes = {'title': ['mocked up title']}
        gwe.creator = ['Kerchner, Daniel']
        gwe.id = ActiveFedora::Noid::Service.new.mint
        gwe.save
        puts gwe.id
      end
    end
  end

  def read_metadata(metadata)
    # BatchIngestLogger.info "Get the metadata for the object"
    puts metadata
    file_attributes = {}
    file_attributes['noid'] = metadata['noid'] if metadata['noid']
    if metadata[:file_location]
      file_attributes['file_location'] = metadata[:file_location]
      file_name = File.basename(metadata[:file_location])
      file_attributes['file_name'] = file_name
    end
    file_attributes['resource_type'] = [metadata[:item_type]] if metadata[:item_type]
    file_attributes['owner_id'] = metadata[:owner_id].split("|") if metadata[:owner_id]
    file_attributes['hasCollectionId'] = [metadata[:collection_noid], metadata[:collection_noid_2], metadata[:collection_noid_3]].compact.delete_if(&:empty?)
    file_attributes['belongsToCommunity'] = [metadata[:community_noid],metadata[:community_noid_2], metadata[:collection_noid_3]].compact.delete_if(&:empty?)
    file_attributes['is_version_of'] = metadata[:is_version_of] if metadata[:is_version_of]
    file_attributes['source'] = metadata[:source] if metadata[:source]
    file_attributes['title'] = [metadata['title']] if metadata['title']
    file_attributes['relation']= metadata[:relation] if metadata[:relation]
    file_attributes['creator'] = metadata[:creator].split("|") if metadata[:creator]
    file_attributes['contributor'] = metadata[:contributor].split("|") if metadata[:contributor]
    file_attributes['description'] = [metadata[:description]] if metadata[:description]
    file_attributes['subject'] = metadata[:subject].split("|") if metadata[:subject]
    file_attributes['license'] = metadata[:license] if metadata[:license]
    file_attributes['rights'] = metadata[:rights] if metadata[:rights]
    file_attributes['date_created'] = metadata[:date_created].to_s if metadata[:date_created]
    file_attributes['language'] = CommonConstants::LANG.fetch(metadata[:language]) if metadata[:language]
    file_attributes['related_url'] = metadata[:related_url] if metadata[:related_url]
    file_attributes['source'] = metadata[:source] if metadata[:source]
    file_attributes['temporal'] = metadata[:temporal].split("|") if metadata[:temporal]
    file_attributes['spatial'] = metadata[:spatial].split("|") if metadata[:spatial]
    file_attributes['embargo_release_date'] = metadata[:embargo_date] if metadata[:embargo_date]
    file_attributes['visibility'] = metadata[:vis_on_ingest] if metadata[:vis_on_ingest]
    file_attributes['visibility_after_embargo'] = metadata[:vis_after_embargo] if metadata[:vis_after_embargo]
    file_attributes['year_created'] = file_attributes['date_created'][/(\d\d\d\d)/, 0] if file_attributes['date_created']

    if file_attributes['license'].nil? and !file_attributes['rights'].nil?
      file_attributes['license'] = "I am required to use/link to a publisher's license"
    end

    collections_title = []
    if file_attributes['hasCollectionId']
      file_attributes['hasCollectionId'].each do |cid|
        begin
          c = Collection.find(cid)
        rescue ActiveFedora::ObjectNotFoundError => not_found_e
          puts "Collection #{cid} not exist, make sure you create the collection first"
        end
        if !c.nil?
          collections_title << c.title
        end
      end
    end
    file_attributes['hasCollection'] = collections_title if !collections_title.empty?

    return file_attributes
  end
end
