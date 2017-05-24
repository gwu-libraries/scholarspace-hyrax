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

  # WARNING:  THIS TASK IS STILL EXPERIMENTAL
  desc "test ingesting Files and attaching to a work"
  task :ingest_files => :environment do
    begin
      user = User.find_by_user_key('kerchner@gwu.edu')
      GwWork
      gwe = GwEtd.new
      gwe.apply_depositor_metadata('kerchner@gwu.edu')
      gwe.id = ActiveFedora::Noid::Service.new.mint
      gwe.title = ["An ETD created via upload"]
      gwe.creator = ["Kerchner, Daniel"]
      gwe.rights = ['http://creativecommons.org/publicdomain/mark/1.0/']
      gwe.resource_type = ['Dissertation']
      fs = FileSet.new
      fs.title = ['Title of the File Set']
      # Look at BatchFileSetActor from https://github.com/pulibrary/plum/blob/master/app/jobs/ingest_mets_job.rb
#      actor = BatchFileSetActor.new(fs, user)
#      actor.attach_related_object(gwe)
#      actor.attach_content(File.open('sample.pdf'))
      actor = ::Hyrax::Actors::FileSetActor.new(fs, user)
      actor.create_metadata()
      actor.create_content(File.open('sample.pdf'))
      actor.attach_file_to_work(gwe)
    end
  end


  desc "ingest an ETD"
  task :ingest_etd, [:manifest_file, :ingest_id] => :environment do |t, args|
    begin
      # Reference GwWork to work around circular dependency
      # problem that would be caused by referencing GwEtd first
      # See articles such as http://neethack.com/2015/04/rails-circular-dependency/
      GwWork
      manifest_file = args.manifest_file
      ingest_id = args.ingest_id 
      if File.exist?(manifest_file)
        mf = File.read(manifest_file)
        manifest_json = JSON.parse(mf.squish)
        etd_id = ingest(manifest_json)
        # generate_ingest_report(noid_list, investigation_id) 
        puts "Created new GwEtd with id = " + etd_id
      else
        puts "file didn't exist - no ingest"
      end
    end
  end

  def ingest(metadata)
    begin
      file_attributes = read_metadata(metadata)
      gwe = GwEtd.new
      gwe.apply_depositor_metadata('kerchner@gwu.edu')
      gwe.attributes = file_attributes
      gwe.id = ActiveFedora::Noid::Service.new.mint
      now = Hyrax::TimeService.time_in_utc
      gwe.date_uploaded = now
      # Other attributes likely needing to be set:
      #  - head[], tail[], state, part_of[], admin_set_id
      #  Once files are loaded, thumbnail_id and/or representative_id
      gwe.save
      return gwe.id
    end
  end

  def read_metadata(metadata)
    # BatchIngestLogger.info "Get the metadata for the object"
    file_attributes = {}
    # resource_type will need some logic around it, TBD
    file_attributes['resource_type'] = ['Dissertation']
    file_attributes['title'] = [metadata['title']] if metadata['title']
    file_attributes['creator'] = [metadata['creator']] if metadata['creator']
    file_attributes['keyword'] = metadata['keyword'] if metadata['keyword']
    file_attributes['contributor'] = metadata['contributor'] if metadata['contributor']
    file_attributes['description'] = [metadata['description']] if metadata['description']
    # TBD whether this is the right rights we want to assign to newly uploaded ETDs
    file_attributes['rights'] = ['http://creativecommons.org/publicdomain/mark/1.0/']
    file_attributes['date_created'] = [metadata['date_created']] if metadata['date_created']
    file_attributes['language'] = [metadata['language']] if metadata['language']
    # We'll need embargo date
    #file_attributes['embargo_release_date'] = metadata['embargo_date'] if metadata['embargo_date']

    return file_attributes
  end
end
