require 'fileutils'
require 'nokogiri'
require 'rake'
require 'zip'

namespace :gwss do
  desc "Creates a bulkrax zip for all of the ProQuest ETD zip files in a folder"
  task :ingest_pq_etds, [:filepath] do |t, args|

    @degree_etd_map = {}

    def get_metadata_doc_path(pq_files_dir)
      xml_paths = Dir.glob("#{pq_files_dir}/*_DATA.xml")
      pq_xml_file_path = xml_paths.first
      pq_xml_file_path
    end

    def get_etd_doc(xml_file_path)
      File.open(xml_file_path) { |f| Nokogiri::XML(f) }
    end

    def get_abstract(doc)
      abstract_text_array = []
      doc.xpath("//DISS_content/DISS_abstract/DISS_para").each do |p|
        abstract_text_array << p.text
      end
      abstract_text = Nokogiri::HTML(abstract_text_array.join("\n")).text
    end

    def fullname(person_node)
      lastname = person_node.xpath("DISS_name/DISS_surname").text
      firstname = person_node.xpath("DISS_name/DISS_fname").text
      middlename = person_node.xpath("DISS_name/DISS_middle").text

      fullname = lastname + ", " + firstname
      fullname = fullname + " " + middlename unless middlename.empty?
      fullname
    end

    def get_creators(doc)
      creators_array = []
      contributors_array = []
      doc.xpath("//DISS_authorship/DISS_author").each do |author_node|
        author_type = author_node.attribute('type').text

        if author_type == 'primary'
          creators_array << fullname(author_node)
        else
          contributors_array << fullname(author_node)
        end 
      end

      {'creators' => creators_array, 'contributors' => contributors_array}
    end

    def get_node_value(doc, xpath)
      doc.xpath(xpath).text
    end

    def get_keywords(doc)
      keyword_array = []
      doc.xpath("//DISS_description/DISS_categorization/DISS_keyword").text.split(',') do |k|
        keyword_array << k.strip()
      end
      keyword_array
    end

    def get_date_created(doc)
      comp_date = doc.xpath("//DISS_description/DISS_dates/DISS_comp_date").text 
      if !comp_date.empty? and comp_date.length >= 4
        comp_date[0..3]
      else
        nil
      end
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

    def get_advisors(doc)
      advisors = []
      doc.xpath("//DISS_description/DISS_advisor").each do |advisor_node|
        advisors << fullname(advisor_node)
      end
      advisors
    end
    
    def get_committee_members(doc)
      committee_members = []
      doc.xpath("//DISS_description/DISS_cmte_member").each do |committee_member_node|
        committee_members << fullname(committee_member_node)
      end
      committee_members
    end

    def convert_to_iso(date_str)
      date = Date.strptime(date_str, '%m/%d/%Y')
      date.strftime('%Y-%m-%d')
    end

    def build_resource_type_degree_mapping
      etd_degree_map = YAML.load_file('config/etd_degree_map.yml')
      @degree_etd_map = {}
      degree_categories = etd_degree_map.keys
      # Flip etd_degree_map to create degree_etd_map
      # So that for any given degree, we can get back whether it's a masters or a doctorate
      degree_categories.each do |degree_category|
        etd_degree_map[degree_category].each do |degree_name|
        # upcase each degree (just in case) and ignore "."s
          @degree_etd_map[degree_name.upcase.delete('.')] = degree_category
        end
      end
    end

    def extract_metadata(doc) 
      work_metadata = Hash.new  
      work_metadata['model'] = 'GwEtd'
      work_metadata['title'] = get_node_value(doc, "//DISS_description/DISS_title")
      creators = get_creators(doc)
      work_metadata['creator'] = creators['creators'].join(';')
      work_metadata['contributor'] = creators['contributors'].join(';')
      work_metadata['language'] = get_node_value(doc, "//DISS_description/DISS_categorization/DISS_language")
      work_metadata['description'] = get_abstract(doc)
      work_metadata['keyword'] = get_keywords(doc).join(';')
      degree = get_node_value(doc, "//DISS_description/DISS_degree")
      work_metadata['degree'] = degree
      work_metadata['resource_type'] = @degree_etd_map[degree.upcase.delete('.')]
      work_metadata['advisor'] = get_advisors(doc).join(';')
      work_metadata['gw_affiliation'] = get_node_value(doc, "//DISS_description/DISS_institution/DISS_inst_contact")
      etd_date_created = get_date_created(doc)
      work_metadata['date_created'] = etd_date_created unless etd_date_created.nil?
      work_metadata['committee_member'] = get_committee_members(doc).join(';')
      work_metadata['rights_statement'] = 'http://rightsstatements.org/vocab/InC/1.0/'
      work_metadata['license'] = 'All rights reserved'
      work_metadata
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

    def repair_filename(filepath)
      # translate spaces in the filename portion to _ 
      if File.dirname(filepath) == '.'
        File.basename(filepath).tr(' ', '_')
      else
        File.join(File.dirname(filepath), File.basename(filepath).tr(' ', '_'))
      end
    end

    build_resource_type_degree_mapping
    puts "build_resource_type_degree_mapping: "
    puts @degree_etd_map
        
    # create folder for metadata.csv and files folder

    # if running spec tests, add /test/ to the tmp file path to prevent filling /tmp/bulkrax_zip when tests are run
    if Rails.env.test?
      bulkrax_zip_path = "#{ENV['TEMP_FILE_BASE']}/test/bulkrax_zip"
    else
      bulkrax_zip_path = "#{ENV['TEMP_FILE_BASE']}/bulkrax_zip"
    end

    bulkrax_files_path = "#{bulkrax_zip_path}/files" 
    FileUtils.makedirs("#{bulkrax_files_path}") unless File.exists?(bulkrax_files_path)

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
      zip_file_dir = "#{bulkrax_files_path}/#{zip_file_basename}" # e.g. bulkrax_zip/files/etdadmin_upload_353614
      Dir.mkdir(zip_file_dir) unless File.exists?(zip_file_dir)

      attachment_file_paths = []
      zip_file.each do |entry|
        puts("  Extracting #{entry.name}")
        entry_name_clean = repair_filename(entry.name)
        zip_file.extract(entry, "#{zip_file_dir}/#{entry_name_clean}") 
        # skip directories - these get their own entries in a zip file
        attachment_file_paths <<  "#{entry_name_clean}" if !entry.name_is_directory?
      end

      # 1. extract the work metdata and add to the works metadata array
      xml_file_path = get_metadata_doc_path(zip_file_dir)
      etd_doc = get_etd_doc(xml_file_path)
      puts "xml is located at: #{xml_file_path}"
      etd_md = extract_metadata(etd_doc)
      etd_md['proquest_zipfile'] = zip_file_basename + '.zip'
      parent_work_identifier = SecureRandom.uuid
      etd_md['bulkrax_identifier'] = parent_work_identifier
      works_metadata << etd_md

      # Set up embargo info that will be applied below to all file attachments
      etd_is_embargoed = is_embargoed?(etd_doc)
      if etd_is_embargoed
        embargo_date = get_embargo_date(etd_doc) 
        if !embargo_date.nil?
          embargo_release_date = convert_to_iso(embargo_date)
        else
          embargo_release_date = nil
        end 
      end

      # 2. extract the attachment files paths and add to the filesets metadata array
      # Remove the metadata xml file so we don't go and attach it to thw work
      attachment_file_paths.delete(File.basename(xml_file_path))
      attachment_file_paths.each do |fp|
        fp_basename = File.basename(fp)
        puts "path = #{fp}, basename = #{fp_basename}"
        file_md = Hash.new
        file_md['model'] = 'FileSet'
        safe_fp = "#{zip_file_basename}/#{fp}"
        file_md['file'] =  safe_fp
        file_md['title'] = fp_basename
        file_md['bulkrax_identifier'] = SecureRandom.uuid
        file_md['parents'] = parent_work_identifier

        # Add embargo info and 
        if etd_is_embargoed
          file_md['visibility'] = 'embargo'
          file_md['visibility_during_embargo'] = 'restricted'
          file_md['visibility_after_embargo'] = 'open'
          file_md['embargo_release_date'] = embargo_release_date
        end
        filesets_metadata << file_md
      end
    end
    
    all_md = works_metadata + filesets_metadata

    csv_rows = hash_array_to_csv_array(all_md)
    bulkrax_csv_filepath = "#{bulkrax_zip_path}/metadata.csv"
    write_csv(csv_rows, bulkrax_csv_filepath)

    # FUTURE EXPANSION:  Zip up the bulkrax ingest manifest and files
    # zip up the working folder
    # Consider a system command here?  Not so simple with rubyzip
  end
end
