abort("The Rails environment is running in production mode!") if Rails.env.production?

ActiveFedora::Cleaner.clean!

# users
admin_user = FactoryBot.create(:admin, email: "admin@example.com")
content_admin_user = FactoryBot.create(:content_admin, email: "content_admin@example.com")
non_admin_user = FactoryBot.create(:user, email: "nonadminuser@example.com")

# admin sets and collection types
default_admin_set_id = AdminSet.find_or_create_default_admin_set_id
admin_set_collection_type = FactoryBot.create(:admin_set_collection_type)
gw_etds_admin_set = FactoryBot.create(:admin_set, title: ["ETDs"])

# collections
5.times do
  FactoryBot.create(:collection, user: admin_user)
end

# works with specific configurations - will need to log in as admin to see them
FactoryBot.create(:work_with_image_files, user: admin_user, title: ["A Work with an Image File"])
FactoryBot.create(:embargoed_work, user: admin_user, title: ["An Embargoed Work"])
FactoryBot.create(:work_with_one_file, user: admin_user, title: ["A Work with a file"])
FactoryBot.create(:work_with_file_and_work, user: admin_user, title: ["A Work with a file and work"])
FactoryBot.create(:work_with_files, user: admin_user, title: ["A Work with files"])
FactoryBot.create(:work_with_one_child, user: admin_user, title: ["A Work with one child"])
FactoryBot.create(:work_with_two_children, user: admin_user, title: ["A Work with two children"])

# public etds with metadata
5.times do |i|
  FactoryBot.create(:public_work, 
                    user: admin_user, 
                    admin_set: gw_etds_admin_set,
                    title: ["Test work with metadata #{i}"],
                    gw_affiliation: ["Department of Testing"],
                    resource_type: ["Research Paper"],
                    creator: ["Professor Goodtests"],
                    contributor: ["Assistant Badtests"],
                    description: ["A work for testing with metadata"],
                    abstract: ["Ey I'm abstracting here"],
                    keyword: ["Testing", "Examining", "Prodding"],
                    license: ["http://www.europeana.eu/portal/rights/rr-r.html"], 
                    rights_notes: [], 
                    rights_statement: ["http://rightsstatements.org/vocab/InC/1.0/"], 
                    access_right: [], 
                    publisher: ["A Pretty Cool Publisher"], 
                    date_created: [rand(1900..2010).to_s], 
                    subject: ["Automated Testing"], 
                    language: ["English"]
                    )
end

# content blocks
ContentBlock.find_or_create_by(name: "header_background_color").update!(value: "#FFFFFF")
ContentBlock.find_or_create_by(name: "header_text_color").update!(value: "#444444")
ContentBlock.find_or_create_by(name: "link_color").update!(value: "#28659A")
ContentBlock.find_or_create_by(name: "footer_link_color").update!(value: "#FFFFFF")
ContentBlock.find_or_create_by(name: "primary_button_background_color").update!(value: "#28659A")
ContentBlock.find_or_create_by(name: "featured_researcher").update!(value: File.open("#{Rails.root}/spec/fixtures/content_blocks/featured_researcher.html").read)
ContentBlock.find_or_create_by(name: "about_page").update!(value: File.open("#{Rails.root}/spec/fixtures/content_blocks/about_page.html").read)
ContentBlock.find_or_create_by(name: "help_page").update!(value: File.open("#{Rails.root}/spec/fixtures/content_blocks/help_page.html").read)
ContentBlock.find_or_create_by(name: "share_page").update!(value: File.open("#{Rails.root}/spec/fixtures/content_blocks/share_page.html").read)

# bundle exec rails db:drop ; bundle exec rails db:create ; bundle exec rails db:migrate ; bundle exec rails db:seed