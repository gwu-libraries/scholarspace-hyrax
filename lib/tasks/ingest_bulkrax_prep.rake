require 'fileutils'
require 'nokogiri'
require 'rake'
require 'zip'

namespace :gwss do
  desc "Creates a bulkrax zip for all of the ProQuest ETD zip files in a folder"
  task :ingest_pq_etds, [:filepath] do |t, args|

    def get_metadata_doc_path(pq_files_dir)
      xml_paths = Dir.glob("#{pq_files_dir}/*_DATA.xml")
      pq_xml_file_path = xml_paths.first
      pq_xml_file_path
    end

    def get_etd_doc(xml_file_path)
      File.open(xml_file_path) { |f| Nokogiri::XML(f) }
    end

    def get_title(doc)
      doc.at_xpath("//DISS_description/DISS_title").text
    end

    def get_language(doc)
      doc.at_xpath("//DISS_description/DISS_categorization/DISS_language").text
    end

    def get_abstract(doc)
      abstract_text_array = []
      doc.xpath("//DISS_content/DISS_abstract/DISS_para").each do |p|
        abstract_text_array << p.text
      end
      abstract_text = Nokogiri::HTML(abstract_text_array.join("\n")).text
    end

    def get_creators(doc)
      creators_array = []
      contributors_array = []
      doc.xpath("//DISS_authorship/DISS_author").each do |a|
        author_type = a.attribute('type').type
        lastname = a.xpath("DISS_name/DISS_surname").text
        firstname = a.xpath("DISS_name/DISS_fname").text
        middlename = a.xpath("DISS_name/DISS_middle").text

        fullname = lastname + ", " + firstname
        fullname = fullname + " " + middlename unless middlename.empty?

        if author_type == 'primary'
          creators_array << fullname
        else
          contributors_array << fullname
        end 
      end

      {'creators' => creators_array, 'contributors' => contributors_array}
    end

    def get_keywords(doc)
      keyword_array = []
      doc.xpath("//DISS_description/DISS_categorization/DISS_keyword").text.split(',') do |k|
        keyword_array << k.strip()
      end
      keyword_array
    end

    def extract_metadata(doc) 
      repo_metadata = Hash.new  
      repo_metadata['model'] = 'GwEtd'
      repo_metadata['title'] = get_title(doc)
      creators = get_creators(doc)
      repo_metadata['creator'] = creators['creators'].join(';')
      repo_metadata['contributor'] = creators['contributors'].join(';')
      repo_metadata['language'] = get_language(doc)
      repo_metadata['description'] = get_abstract(doc)
      repo_metadata['keyword'] = get_keywords(doc).join(';')
      repo_metadata
    end

    def is_embargoed?(doc)
      sales_restric = doc.xpath("//DISS_restriction/DISS_sales_restriction")
      return false if sales_restric.empty?
      rmv = sales_restric.attribute('remove')
      return false if rmv.nil?
      # else
      true
    end

    def get_embargo_date(doc)
      sales_restric = doc.xpath("//DISS_restriction/DISS_sales_restriction")
      return nil if sales_restric.empty?
      return nil if sales_restric.attribute('remove').text.empty?
      sales_restric.attribute('remove').text
    end

    def convert_to_iso(date_str)
      date = Date.strptime(date_str, '%m/%d/%Y')
      date.strftime('%Y-%m-%dT00:00:00')
    end

    def hash_array_to_csv_array(hash_array)
      hash_keys = hash_array.flat_map(&:keys).uniq
      # header row
      csv_array = [hash_keys]
      hash_array.each do |row|
        csv_array << hash_keys.map {|key| row[key]}
      end
      csv_array
    end

    def write_csv(csv_array, csv_path)
      CSV.open(csv_path, 'w') do |csv|
        csv_array.each do |row|
          csv << row
        end
      end
    end
        
    # create folder for metadata.csv and files folder 
    bulkrax_zip_path = "#{ENV['TEMP_FILE_BASE']}/bulkrax_zip" 
    bulkrax_files_path = "#{ENV['TEMP_FILE_BASE']}/bulkrax_zip/files" 
    puts "File.exists?(bulkrax_zip_path) = #{File.exists?(bulkrax_zip_path)}"
    FileUtils.makedirs("#{bulkrax_files_path}") unless File.exists?(bulkrax_zip_path)

    # get all ETD zip files in the args.filepath folder
    path_to_zips = args.filepath

    works_metadata = []
    filesets_metadata = []

    zip_paths = Dir.glob("#{path_to_zips}/etdadmin*.zip")
    puts("zip_paths: #{zip_paths}")
    zip_paths.each do |zip_path|
      # for each ETD zip file:
      puts("Processing #{zip_path}")
      zip_file = Zip::File.open(zip_path)
      zip_file_basename = File.basename(zip_path, '.zip') # e.g. etdadmin_upload_353614
      # Dir.mkdir("#{ENV['TEMP_FILE_BASE']}/etds") unless File.exists?("#{ENV['TEMP_FILE_BASE']}/etds")
      # zip_file_dir = "#{ENV['TEMP_FILE_BASE']}/etds/#{zip_file_basename}" 
      zip_file_dir = "#{bulkrax_files_path}/#{zip_file_basename}" # e.g. bulkrax_zip/files/etdadmin_upload_353614
      Dir.mkdir(zip_file_dir) unless File.exists?(zip_file_dir)

      attachment_file_paths = []
      zip_file.each do |entry|
        puts("  Extracting #{entry.name}")
        zip_file.extract(entry, "#{zip_file_dir}/#{entry.name}") 
        # attachment_file_paths <<  "#{zip_file_dir}/#{entry.name}" if !entry.name_is_directory?
        attachment_file_paths <<  "#{entry.name}" if !entry.name_is_directory?
      end

      # 1. extract the work metdata and add to the works metadata array
      xml_file_path = get_metadata_doc_path(zip_file_dir)
      etd_doc = get_etd_doc(xml_file_path)
      puts "xml is at: #{xml_file_path}"
      etd_md = extract_metadata(etd_doc)
      parent_work_identifier = SecureRandom.uuid
      etd_md['bulkrax_identifier'] = parent_work_identifier
      puts etd_md
      works_metadata << etd_md

      # 2. extract the attachment files paths and add to the filesets metadata array
      attachment_file_paths.delete(File.basename(xml_file_path))
      # Dir.mkdir("#{bulkrax_zip_path}/#{zip_file_basename}") if !attachment_file_paths.empty?
      attachment_file_paths.each do |fp|
        fp_basename = File.basename(fp)
        puts "path = #{fp}, basename = #{fp_basename}"
        file_md = Hash.new
        file_md['model'] = 'FileSet'
        # safe_fp = File.dirname("#{zip_file_basename}/#{fp}") + '/"' + File.basename(fp) + '"'
        safe_fp = "#{zip_file_basename}/#{fp}"
        file_md['file'] =  safe_fp
        file_md['title'] = fp_basename
        file_md['bulkrax_identifier'] = SecureRandom.uuid
        file_md['parents'] = parent_work_identifier
        # Add embargo info to file_md
        if is_embargoed?(etd_doc)
          # Get embargo info
          embargo_date = get_embargo_date(etd_doc)
          # TODO: Convert to isoformat as per Python DateTime.isoformat()
          file_md['visibility'] = 'embargo'
          file_md['visibility_during_embargo'] = 'restricted'
          file_md['visibility_after_embargo'] = 'open'
          if !embargo_date.nil?
            file_md['embargo_release_date'] = convert_to_iso(embargo_date)
          else
            file_md['embargo_release_date'] = nil
          end 
        end
        filesets_metadata << file_md

        # FileUtils::copy_file(fp, "#{bulkrax_zip_path}/#{zip_file_basename}/#{fp_basename}")
      end
    end
    
    # puts("works_metadata: #{works_metadata}")
    # puts("files_metadata: #{filesets_metadata}")
    all_md = works_metadata + filesets_metadata
    # puts("all_md: #{all_md}")

    csv_rows = hash_array_to_csv_array(all_md)
    # Don't delete this:  We need to resurrect it in order to put each ETD's files in a separate directory
    # to avoid name collisions
    #bulkrax_zip_spec_path = "#{bulkrax_zip_path}/#{zip_file_basename}"
    #Dir.mkdir(bulkrax_zip_spec_path) unless File.exists?(bulkrax_zip_spec_path)
    bulkrax_csv_filepath = "#{bulkrax_zip_path}/metadata.csv"
    write_csv(csv_rows, bulkrax_csv_filepath)

    # create metadata CSV from the works metadata array and the filesets array
    # zip up the working folder
    # Consider a system command here?  Not so simple with rubyzip
  end

  desc "Ingests ProQuest XML metadata for a single ETD"
  task :ingest_etd_new, [:filepath] do |t, args|

    # attr_accessor :etd_doc, :repo_metadata

    def extract_zip(zip_file_path)
      puts("filepath is #{zip_file_path}")
      zip_file = Zip::File.open(zip_file_path)
      zip_file_basename = File.basename(zip_file_path, '.zip')
      Dir.mkdir(zip_file_basename) unless File.exists?(zip_file_basename)
      
      zip_file.each do |component_file|
        puts "Extracting #{component_file.name}"
        zip_file.extract(component_file, "#{zip_file_basename}/#{component_file.name}")
      end

      # return path to files
      zip_file_basename
    end

    def get_metadata_doc_path(pq_files_dir)
      xml_paths = Dir.glob("#{pq_files_dir}/*.xml")
      pq_xml_file_path = xml_paths.first
      pq_xml_file_path
    end

    def get_etd_doc(xml_file_path)
      File.open(xml_file_path) { |f| Nokogiri::XML(f) }
    end
    
    def extract_metadata(doc) 
      repo_metadata = Hash.new  
    end

    def get_title(doc)
      doc.at_xpath("//DISS_description/DISS_title").text
    end

    def get_language(doc)
      doc.at_xpath("//DISS_description/DISS_categorization/DISS_language").text
    end

    def get_abstract(doc)
      # TODO: 
      abstract_text_array = []
      doc.xpath("//DISS_content/DISS_abstract/DISS_para").each do |p|
        abstract_text_array << p.text
      end
      abstract_text = Nokogiri::HTML(abstract_text_array.join("\n")).text
    end

    files_dir = extract_zip(args.filepath)
    xml_doc_path = get_metadata_doc_path(files_dir)
    etd_doc = get_etd_doc(xml_doc_path)

    repo_metadata = Hash.new
    repo_metadata['title'] = get_title(etd_doc)
    repo_metadata['language'] = get_language(etd_doc)
    repo_metadata['description'] = get_abstract(etd_doc)

    puts repo_metadata
  end
end

