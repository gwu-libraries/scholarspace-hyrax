require 'nokogiri'
require 'rake'
require 'zip'

namespace :gwss do
  desc "Creates a bulkrax zip for all of the ProQuest ETD zip files in a folder"
  task :ingest_pq_etds, [:filepath] do |t, args|
    # create folder for metadata.csv and files folder 
    Dir.mkdir('bulkrax_zip') unless File.exists?('bulkrax_zip')

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
      zip_file_basename = File.basename(zip_path, '.zip')
      Dir.mkdir("/tmp/#{zip_file_basename}") unless File.exists?(zip_file_basename)
      zip_file.each do |component_file|
        puts("  Extracting #{component_file.name}")
        zip_file.extract(component_file, "/tmp/#{zip_file_basename}/#{component_file.name}") 
      end
      # 1. extract the work metdata and add to the works metadata array
      # 2. extract the embargo info
      # 3. add files info (w/embargo info) to the filesets array
      # 4. copy the file attachments to the 'files' folder
    end

    # create metadata CSV from the works metadata array and the filesets array
    # zip up the working folder
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
