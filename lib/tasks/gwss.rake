require 'fileutils'
require 'json'
require 'optparse'

namespace :gwss  do
  # adding a logger since it got removed from our gemset
  #def logger
  #  Rails.logger
  #end

  desc "Queues a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    SitemapRegenerateJob.perform_later
  end

  desc "Create GW ScholarSpace user roles"
  task create_roles: :environment do
    adminrole = Role.find_or_create_by(name: 'admin')
    adminrole.save

    contentadminrole = Role.find_or_create_by(name: 'content-admin')
    contentadminrole.save
  end

  desc "Ingest an ETD"
  task :ingest_etd => :environment do |t, args|
    begin
      options = {}

      op = OptionParser.new
      op.banner = "Usage: rake gwss:ingest_etd -- --manifest=MFPATH --primaryfile=PFPATH --otherfiles=OFLIST --depositor=DEPOSITOR --update-item-id=UPDATEID"
      op.on('-mf MFPATH', '--manifest=MFPATH', 'Path to manifest file') { |mfpath| options[:mfpath] = mfpath }
      op.on('-pf FPATH', '--primaryfile=PFPATH', 'Path to primary attachment file') { |pfpath| options[:pfpath] = pfpath }
      op.on('-of OFLIST', '--otherfiles=OFLIST', 'Comma-separated list of paths to supplemental files') { |oflist| options[:oflist] = oflist }
      op.on('-dep DEPOSITOR', '--depositor=DEPOSITOR', 'Scholarspace ID (e.g. email) of depositor') { |depositor| options[:depositor] = depositor }
      op.on('--update-item-id[=UPDATEID]', 'Update Item ID') { |updateid| options[:updateid] = updateid }

      # return `ARGV` with the intended arguments
      args = op.order!(ARGV) {}
      op.parse!(args)

      ## uncomment if we decide to throw exceptions for missing options
      # raise OptionParser::MissingArgument if options[:name].nil?

      # Reference GwWork to work around circular dependency
      # problem that would be caused by referencing GwEtd first
      # See articles such as http://neethack.com/2015/04/rails-circular-dependency/
      GwWork
      manifest_file = options[:mfpath]
      if File.exist?(manifest_file)
        mf = File.read(manifest_file)
        manifest_json = JSON.parse(mf.squish)
        item_attributes = read_metadata(manifest_json)
        etd_id = ingest(item_attributes, options[:depositor], options[:updateid])
        # generate_ingest_report(noid_list, investigation_id) 
        attach_files(options[:pfpath], options[:oflist],
                     options[:depositor], item_attributes['embargo_release_date'], etd_id)
        puts etd_id
      else
        puts "Manifest file doesn't exist - no ingest"
      end
    end
  end

  def ingest(item_attributes, depositor, updateid)
    begin
      gwe = nil
      if updateid.nil?
        gwe = GwEtd.new
        gwe.id = ActiveFedora::Noid::Service.new.mint
      else
        gwe = GwEtd.find(updateid)
        # delete existing files; we'll "overwrite" with new ones
        # TODO: Unfortunately, this will have the effect that links
        # to individual files won't be persistent if the ETD is updated
        # To solve this, we'd need a scheme for matching up updated files
        # with existing files (perhaps by file name?)
        fsets = gwe.file_sets
        fsets.each do |fs|
          fs.delete  
        end
      end

      gwe.apply_depositor_metadata(depositor)
      gwe.attributes = item_attributes
      gwe.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      now = Hyrax::TimeService.time_in_utc
      gwe.date_uploaded = now

      etd_admin_set = AdminSet.where(title: "ETDs")[0]
      gwe.admin_set = etd_admin_set
      gwe.set_edit_groups(["content-admin"],[])
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
    file_attributes['gw_affiliation'] = [metadata['gw_affiliation']] if metadata['gw_affiliation']
    file_attributes['degree'] = metadata['degree'] if metadata['degree']
    file_attributes['advisor'] = metadata['advisors'] if metadata['advisors']
    file_attributes['committee_member'] = metadata['committee_members'] if metadata['committee_members']
    # TBD whether this is the right rights we want to assign to newly uploaded ETDs
    file_attributes['rights'] = ['http://www.europeana.eu/portal/rights/rr-r.html']
    file_attributes['date_created'] = [metadata['date_created']] if metadata['date_created']
    file_attributes['language'] = [metadata['language']] if metadata['language']
    file_attributes['embargo_release_date'] = metadata['embargo_date'] if metadata['embargo_date']

    return file_attributes
  end

  def attach_files(primaryfile_path, otherfiles_list, depositor, embargo_release_date, etd_id)
    user = User.find_by_user_key(depositor)
    gwe = GwEtd.find(etd_id)
    # add primary file first, other files afterwards
    files = []
    files += [primaryfile_path] if primaryfile_path
    files += otherfiles_list.split(',') if otherfiles_list
    files.each do |f|
      fs = FileSet.new
      # use the filename as the FileSet title
      fs.title = [File.basename(f)]
      actor = ::Hyrax::Actors::FileSetActor.new(fs, user)
      actor.create_metadata()
      actor.create_content(File.open(f))
      actor.attach_file_to_work(gwe)
      if embargo_release_date
        fs.apply_embargo(embargo_release_date,
                      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
                      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
      fs.set_edit_groups(["content-admin"],[])
      fs.save
    end
  end

  desc "Reindex everything"
  task reindex_all: :environment do
    ActiveFedora::Base.reindex_everything
  end
end
