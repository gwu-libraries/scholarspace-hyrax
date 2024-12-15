require 'fileutils'
require 'aws-sdk-s3'
require 'nokogiri'
require 'rake'
require 'zip'
require 'csv'

namespace :gwss do
  # Build index of ETD PDF file name --> Proquest zip file name
  # using proquest ETDs as ground truth
  # look in bulkrax code to borrow code for unzipping etc.
  desc "Adds ProQuest zipfile names to metadata of current GwETDs"
  task :populate_etd_proquest_zipfile => :environment do
    # Builds a hash that maps each proquest zip file name to its PDF file name,
    # for all ProQuest ETD zip files in S3
    def build_pq_mapping_hash
      puts "Building a hash mapping ETD PDF file names to proquest zip file names"
      pq_hash = {}
      
      bucket_name = ENV['AWS_PROQUEST_ETD_BUCKET_NAME']
      s3_bucket_client = Aws::S3::Bucket.new(name: bucket_name)
       
      # Set up a temporary location to open up one zip at a time
      destination_dir = './temp_pq_etds' 
      Dir.mkdir(destination_dir) unless Dir.exist?(destination_dir)

      # List out all the zip file names
      object_name_list = s3_bucket_client.objects.map(&:key)
      object_name_list.each do |object_name|
        obj_client = Aws::S3::Object.new(bucket_name: bucket_name, key: object_name)

        # Download the proquest zip file
        destination_path = File.join(destination_dir, File.basename(object_name))
        obj_client.get(response_target: destination_path)

        # Open it up, find the XML file, convert that to PDF file name (they always match)
        Zip::File.open(destination_path) do |zip_file|
          data_xml_files = zip_file.select { |entry| entry.name.match?(/\_DATA.xml$/i) }
          pdf_fn = data_xml_files[0].name.gsub('_DATA.xml', '.pdf')
          pq_hash[pdf_fn] = object_name
          puts "\t#{object_name} --> #{pdf_fn}"
        end

        # Clean up
        File.delete(destination_path)
      end
      return pq_hash
    end
    
    # Returns hash of existing GwETD ids to PDF file names
    def build_etd_pdf_hash
      puts "Mapping each existing GwETD id to its PDF file name"
      etd_pdf_hash = {}
      GwEtd.find_each do |etd|
        etd_id = etd.id
        fsets = etd.file_sets
        fn_list = fsets.map(&:label)
        pattern = /\w*_gwu_0075A_\w*\.pdf/
        matching_files = fn_list.select { |filename| filename.match?(pattern) }

        etd_pdf_hash[etd_id] = matching_files[0]
        puts "\t#{etd_id} => #{matching_files[0]}"
      end
      return etd_pdf_hash
    end
    
    # Adds proquest_zipfile values to current GwETDs
    def enrich_etds(etdfn_to_zipfn, etdid_to_etdfn)
      puts "Adding proquest_zipfile values to GwETDs..."
      etdid_to_etdfn.each do |etdid, etdfn|
        puts "\t#{etdid}...#{etdfn}"
        etd = GwEtd.find(etdid)
        unless etdfn.nil?
          etd['proquest_zipfile'] = etdfn_to_zipfn[etdfn]
          etd.save
        end
      end
    end

    # Build mapping hash (ETD PDF file name => pq original zip file name)
    pq_hash = build_pq_mapping_hash()
    # Map GwEtd ID => ETD PDF file name
    etd_pdf_hash = build_etd_pdf_hash()
    # Update GwEtd objects' metadata
    enrich_etds(pq_hash, etd_pdf_hash)
  end

  # Check for proquest zips in S3 that don't yet exist in GWSS
  # Download them from S3 to the path specified in the argument.
  desc "Download ProQuest zip files not matching ETDs currently in GWSS"
  task :download_new_pq_zips, [:filepath] => :environment do |t, args|
    
    # Returns a list of the ProQuest zip files currently in S3
    def get_s3_pq_zip_names
      bucket_name = ENV['AWS_PROQUEST_ETD_BUCKET_NAME']
      s3_bucket_client = Aws::S3::Bucket.new(name: bucket_name)
      object_name_list = s3_bucket_client.objects.map(&:key)
      object_name_list
    end

    # Returns a Set of the zipfile names in the proquest_zipfile metadata values
    # of current GwETD works
    def get_gwss_pq_zipfiles_set
      etds = GwEtd.all
      etd_zipfiles_list = etds.map(&:proquest_zipfile)
      etd_zipfiles_set = Set.new(etd_zipfiles_list)
      etd_zipfiles_set
    end

    # Download a list of specific ProQuest zip files from S3
    def download_s3_pq_zipfiles(destination_dir, zf_list)
      bucket_name = ENV['AWS_PROQUEST_ETD_BUCKET_NAME']
      zf_list.each do |zf_name|
        obj_client = Aws::S3::Object.new(bucket_name: bucket_name, key: zf_name)
        destination_path = File.join(destination_dir, File.basename(zf_name))
        obj_client.get(response_target: destination_path)
        puts "Downloading #{zf_name} to #{destination_dir}"
      end
    end
    
    s3_pq_zipnames = get_s3_pq_zip_names()
    etd_zipfiles_set = get_gwss_pq_zipfiles_set()
    # Do a "diff" to get only zipfiles that are NOT associated with current GwETDs
    new_proquest_zipfiles = s3_pq_zipnames.reject {|zf| etd_zipfiles_set.include?(zf)} 

    path_to_zips = args.filepath
    download_s3_pq_zipfiles(path_to_zips, new_proquest_zipfiles)
  end
end