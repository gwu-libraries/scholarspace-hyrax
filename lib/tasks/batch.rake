require 'fileutils'
require 'csv'
require 'json'

namespace :batch do
  desc "batch ingest from a csv file - intended for ETD uploads for GW ScholarSpace"
  task :ingest_csv, [:file, :tmp_dir, :mode] => :environment do |t, args|
    begin
      puts "Starting batch ingest"
      input_file = args.file
      puts "Ingestng from #{input_file} "
      if File.exist?(input_file)
         json = convert_csv_json(input_file)
      end
      puts "Finishing batch ingest"
    end
  end

  def convert_csv_json(file)
    csv = CSV.open(file, :headers => true, :header_converters => :symbol, :converters => :all)
    json = csv.map{ |x| x.to_h }
    puts json
    return json
  end

end
