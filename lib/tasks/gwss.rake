require 'fileutils'
require 'json'
require 'optparse'

namespace :gwss  do
  # adding a logger since it got removed from our gemset
  #def logger
  #  Rails.logger
  #end

  desc "Deletes null keywords from GwEtds"
  task "delete_null_keywords" => :environment do
    ids = Hyrax::SolrService.new.get("has_model_ssim:GwEtd NOT keyword_tesim:*", fl: [:id], rows: 1_000_000)
    ids["response"]["docs"].each do |doc|
      work = GwEtd.find(doc["id"])
      if (work.keyword.length == 1) and (work.keyword[0] == "") 
        work.keyword = []
        work.save
      end
    end
  end

  desc "Queues a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    SitemapRegenerateJob.perform_later
  end

  desc "Creates the default Admin Set if it doesn't exist"
  task create_admin_set: :environment do
    if !AdminSet.exists?("admin_set/default")
      # Delegate to Hyrax task
      Rake::Task["hyrax:default_admin_set:create"].invoke
    end
  end

  desc "Create GW ScholarSpace user roles"
  task create_roles: :environment do
    adminrole = Role.find_or_create_by(name: 'admin')
    adminrole.save

    contentadminrole = Role.find_or_create_by(name: 'content-admin')
    contentadminrole.save
  end

  desc "Add a user to the admin role"
  task :add_admin_role => :environment do
    if User.find_by(email: ENV['DEV_ADMIN_USER_EMAIL']) == nil
      admin_user = User.create(email: ENV['DEV_ADMIN_USER_EMAIL'], password: ENV['DEV_ADMIN_USER_PASSWORD'])
      admin_role = Role.find_or_create_by(name: 'admin')
      admin_role.users << admin_user  
    end

    if User.find_by(email: ENV['DEV_CONTENT_ADMIN_USER_EMAIL']) == nil
      content_admin_user = User.create(email: ENV['DEV_CONTENT_ADMIN_USER_EMAIL'], password: ENV['DEV_CONTENT_ADMIN_USER_PASSWORD'])
      content_admin_role = Role.find_or_create_by(name: 'content-admin')
      content_admin_role.users << content_admin_user
    end
  end

  desc "Ingest a Work"
  task :ingest_work => :environment do |t, args|
    begin
      options = {}

      op = OptionParser.new
      op.banner = "Usage: rake gwss:ingest_work -- --manifest=MFPATH --primaryfile=PFPATH --otherfiles=OFLIST --depositor=DEPOSITOR --update-item-id=UPDATEID"
      op.on('-mf MFPATH', '--manifest=MFPATH', 'Path to manifest file') { |mfpath| options[:mfpath] = mfpath }
      op.on('-pf FPATH', '--primaryfile=PFPATH', 'Path to primary attachment file') { |pfpath| options[:pfpath] = pfpath }
      op.on('-of OFLIST', '--otherfiles=OFLIST', 'Comma-separated list of paths to supplemental files') { |oflist| options[:oflist] = oflist }
      op.on('-dep DEPOSITOR', '--depositor=DEPOSITOR', 'Scholarspace ID (e.g. email) of depositor') { |depositor| options[:depositor] = depositor }
      op.on('--set-item-id[=UPDATEID]', 'Set Item ID') { |setid| options[:setid] = setid }
      op.on('--update-item-id[=UPDATEID]', 'Update Item ID') { |updateid| options[:updateid] = updateid }
      op.on('--skip-file-updates', 'If upload, do not delete existing files') { options[:skip_file_updates] = true }
      op.on('--private', 'Ingest and create with Private visibility') { options[:private] = true }

      # return `ARGV` with the intended arguments
      args = op.order!(ARGV) {}
      op.parse!(args)

      raise OptionParser::MissingArgument if options[:mfpath].nil?
      raise OptionParser::MissingArgument if options[:depositor].nil?

      manifest_file = options[:mfpath]
      if File.exist?(manifest_file)
        mf = File.read(manifest_file)
        manifest_json = JSON.parse(mf.squish)
        item_attributes = manifest_json.dup
        item_attributes.delete('embargo')
        item_attributes.delete('embargo_release_date')
        
        # dc:rights
        # There are some items with extraneous 'None' values; remove these
        licenses = (manifest_json['license'] or []) - ['None']
        if licenses.length == 0
          item_attributes['license'] = ['http://www.europeana.eu/portal/rights/rr-r.html']
        else
          item_attributes['license'] = licenses
        end

        # edm:rights
        # turn this scalar value into a single-valued list
        item_attributes['rights_statement'] = [manifest_json['rights_statement']]

        work_id = ingest_work(item_attributes, options[:depositor], options[:updateid], options[:setid], options[:private], options[:skip_file_updates])
        # generate_ingest_report(noid_list, investigation_id) 
        embargo_attributes = read_embargo_info(manifest_json)
        gww = GwWork.find(work_id)
        unless !options[:updateid].nil? && options[:skip_file_updates]
          attach_files(gww, options[:pfpath], options[:oflist],
                       options[:depositor], embargo_attributes)
        end
        puts work_id
      else
        puts "Manifest file doesn't exist - no ingest"
      end
    end
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

      raise OptionParser::MissingArgument if options[:mfpath].nil?
      raise OptionParser::MissingArgument if options[:pfpath].nil?
      raise OptionParser::MissingArgument if options[:depositor].nil?

      # Reference GwWork to work around circular dependency
      # problem that would be caused by referencing GwEtd first
      # See articles such as http://neethack.com/2015/04/rails-circular-dependency/
      GwWork
      manifest_file = options[:mfpath]
      if File.exist?(manifest_file)
        mf = File.read(manifest_file)
        manifest_json = JSON.parse(mf.squish)
        item_attributes = manifest_json.dup
        # Since we're going to embargo the file, not the item:
        item_attributes.delete('embargo')
        item_attributes.delete('embargo_release_date')
        if manifest_json['degree']
          item_attributes['degree'] = manifest_json['degree'][0]
        end
        # resource_type may need more logic around it, TBD
        item_attributes['resource_type'] = ['Thesis or Dissertation']

        # dc:rights
        # Always set this license for ETDs
        item_attributes['license'] = ['http://www.europeana.eu/portal/rights/rr-r.html']
        item_attributes.delete('rights')

        # edm:rights
        # Always set this rights statement for ETDs
        item_attributes['rights_statement'] = ['http://rightsstatements.org/vocab/InC/1.0/']

        etd_id = ingest_etd(item_attributes, options[:depositor], options[:updateid])
        # generate_ingest_report(noid_list, investigation_id) 
        embargo_attributes = read_embargo_info(manifest_json)
        gwe = GwEtd.find(etd_id)
        attach_files(gwe, options[:pfpath], options[:oflist],
                     options[:depositor], embargo_attributes)
        puts etd_id
      else
        puts "Manifest file doesn't exist - no ingest"
      end
    end
  end

  def ingest_work(item_attributes, depositor, updateid, setid, visibility_private, skip_file_updates)
    begin
      gww = nil
      if updateid.nil?
        gww = GwWork.new
        if setid.nil?
          gww.id = Noid::Rails::Service.new.mint
        else
          gww.id = setid
        end
      else
        gww = GwWork.find(updateid)
        # delete existing files; we'll "overwrite" with new ones
        # TODO: Unfortunately, this will have the effect that links
        # to individual files won't be persistent if the ETD is updated
        # To solve this, we'd need a scheme for matching up updated files
        # with existing files (perhaps by file name?)
        unless skip_file_updates
          fsets = gww.file_sets
          fsets.each do |fs|
            fs.delete
          end
        end
      end

      gww.apply_depositor_metadata(depositor)
      gww.attributes = item_attributes
      if visibility_private
        gww.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      else
        gww.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
      now = Hyrax::TimeService.time_in_utc
      gww.date_uploaded = now

      # Add to Default Administrative Set
      default_admin_set_id = AdminSet.find_or_create_default_admin_set_id
      default_admin_set = AdminSet.find(default_admin_set_id)
      gww.admin_set = default_admin_set
      gww.set_edit_groups(["content-admin"],[])
      gww.save

      return gww.id
    end
  end

  def ingest_etd(item_attributes, depositor, updateid)
    begin
      gwe = nil
      if updateid.nil?
        gwe = GwEtd.new
        gwe.id = Noid::Rails::Service.new.mint
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

  def read_embargo_info(metadata)
    embargo_info = {}
    embargo_info['embargo'] = metadata['embargo'] == true ? true : false
    if embargo_info['embargo'] == true
      embargo_info['embargo_release_date'] = metadata['embargo_release_date'].nil? ? '2100-01-01' : metadata['embargo_release_date']
    end

    return embargo_info
  end

  def attach_files(work, primaryfile_path, otherfiles_list, depositor, embargo_attributes)
    user = User.find_by_user_key(depositor)
    # add primary file first, other files afterwards
    files = []
    files += [primaryfile_path] if primaryfile_path
    files += otherfiles_list.split(',') if otherfiles_list
    files.each do |f|
      fs = FileSet.new
      # use the filename as the FileSet title
      fs.id = Noid::Rails::Service.new.mint
      fs.title = [File.basename(f)]
      actor = ::Hyrax::Actors::FileSetActor.new(fs, user)
      actor.create_metadata()
      actor.create_content(File.open(f))
      actor.attach_to_work(work)
      if embargo_attributes['embargo'] == true
        fs.apply_embargo(embargo_attributes['embargo_release_date'],
                      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
                      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end
      fs.set_edit_groups(["content-admin"],[])
      fs.save
    end
  end

  desc "Reindex everything"
  task reindex_everything: :environment do
    ActiveFedora::Base.reindex_everything
  end

  desc "Apply ContentBlock changes"
  task apply_contentblock_changes: :environment do
    featured_researcher_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/featured_researcher.html")
    about_page_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/about_page.html")
    help_page_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/help_page.html")

    ContentBlock.find_or_create_by(name: "header_background_color").update!(value: "#FFFFFF")
    ContentBlock.find_or_create_by(name: "header_text_color").update!(value: "#444444")
    ContentBlock.find_or_create_by(name: "link_color").update!(value: "#28659A")
    ContentBlock.find_or_create_by(name: "footer_link_color").update!(value: "#FFFFFF")
    ContentBlock.find_or_create_by(name: "primary_buttom_background_color").update!(value: "#28659A")
    ContentBlock.find_or_create_by(name: "featured_researcher").update!(value: featured_researcher_html.read)
    ContentBlock.find_or_create_by(name: "about_page").update!(value: about_page_html.read)
    ContentBlock.find_or_create_by(name: "help_page").update!(value: help_page_html.read)
  end
end
