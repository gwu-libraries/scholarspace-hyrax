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

  desc "Executes (immediately) a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    SitemapRegenerateJob.perform_now
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

  desc "Reindex everything"
  task reindex_everything: :environment do
    ActiveFedora::Base.reindex_everything
  end

  desc "Apply ContentBlock changes"
  task apply_contentblock_changes: :environment do
    featured_researcher_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/featured_researcher.html")
    about_page_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/about_page.html")
    help_page_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/help_page.html")
    share_page_html = File.open("#{Rails.root}/spec/fixtures/content_blocks/share_page.html")

    ContentBlock.find_or_create_by(name: "header_background_color").update!(value: "#FFFFFF")
    ContentBlock.find_or_create_by(name: "header_text_color").update!(value: "#444444")
    ContentBlock.find_or_create_by(name: "link_color").update!(value: "#28659A")
    ContentBlock.find_or_create_by(name: "footer_link_color").update!(value: "#FFFFFF")
    ContentBlock.find_or_create_by(name: "primary_button_background_color").update!(value: "#28659A")
    ContentBlock.find_or_create_by(name: "featured_researcher").update!(value: featured_researcher_html.read)
    ContentBlock.find_or_create_by(name: "about_page").update!(value: about_page_html.read)
    ContentBlock.find_or_create_by(name: "help_page").update!(value: help_page_html.read)
    ContentBlock.find_or_create_by(name: "share_page").update!(value: share_page_html.read)
  end

  desc "Reassigns GwEtd resource_type values to Master's Thesis or Dissertation"
  task "reassign_etd_resource_types" => :environment do
    etd_degree_map = YAML.load_file('config/etd_degree_map.yml')
    degree_etd_map = {}
    degree_categories = etd_degree_map.keys
    # Flip etd_degree_map to create degree_etd_map
    # So that for any given degree, we can get back whether it's a masters or a doctorate
    degree_categories.each do |degree_category|
      etd_degree_map[degree_category].each do |degree_name|
        # upcase each degree (just in case) and ignore "."s
        degree_etd_map[degree_name.upcase.delete('.')] = degree_category
      end
    end

    ids = Hyrax::SolrService.new.get("has_model_ssim:GwEtd", fl: [:id], rows: 1_000_000)
    ids["response"]["docs"].each do |doc|
      work = GwEtd.find(doc["id"])
      if work.degree.nil?
        puts "GwEtd id=#{doc["id"]} degree is empty! Skipping"
      else
        degree_name = work.degree.upcase.delete('.')
        if degree_etd_map.keys.include?(degree_name)
          work.resource_type = [degree_etd_map[degree_name]]
          work.save
          puts "Reassigned #{degree_name} resource type to #{degree_etd_map[degree_name]}"
        else
          puts "Degree name #{degree_name} not found! Skipping"
        end
      end
    end
  end

  desc "Enumerates degree types present among existing GwEtd works"
  task "enumerate_degree_types" => :environment do
    ids = Hyrax::SolrService.new.get("has_model_ssim:GwEtd", fl: [:id], rows: 1_000_000)
    docs = ids["response"]["docs"]
    # Map a list of ids to a list of degree values
    degrees = docs.map {|doc| GwEtd.find(doc["id"]).degree}
    degree_hash = degrees.tally
    degree_hash.keys.each do |key|
      puts "#{key}, #{degree_hash[key]}"
    end
  end
end
