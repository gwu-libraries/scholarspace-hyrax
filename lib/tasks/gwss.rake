require 'csv'
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

  desc "batch ingest from a csv file"
  task :ingest_csv, [:manifest, :batchfiles_path, :ingest_id] => :environment do |t, args|
    begin
      puts "starting batch ingest"
      manifest = args.manifest
      puts manifest
      batchfiles_path = args.batchfiles_path
      ingest_id = args.ingest_id 
      if File.exist?(manifest)
        json = convert_csv_json(manifest)
        noid_list = ingest(json, batchfiles_path)
        # generate_ingest_report(noid_list, investigation_id) 
      else
        puts "file didn't exist - no ingest"
      end
    end
  end

  def ingest(json, batchfiles_path)
    noid_list=[]
    json.each do |metadata|
      begin
        puts metadata
      end
    end
  end

  def convert_csv_json(file)
    csv = CSV.open(file, :headers => true, :header_converters => :symbol, :converters => :all)
    json = csv.map{ |x| x.to_h }
    return json
  end
end
