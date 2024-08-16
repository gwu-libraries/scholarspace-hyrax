abort("The Rails environment is running in production mode!") if Rails.env.production?

ActiveFedora::Cleaner.clean!

# users
admin_user = FactoryBot.create(:admin, email: "admin@example.com")
content_admin_user = FactoryBot.create(:content_admin, email: "content_admin@example.com")
non_admin_user = FactoryBot.create(:user, email: "nonadminuser@example.com")

# admin sets and collection types
default_admin_set_id = FactoryBot.create(:stored_default_admin_set_id)
admin_set_collection_type = FactoryBot.create(:admin_set_collection_type)
gw_etds_admin_set = FactoryBot.create(:admin_set, title: ["ETDs"],edit_users: [admin_user.user_key, content_admin_user.user_key])

permission_template = FactoryBot.create(:permission_template, source_id: gw_etds_admin_set.id, with_admin_set: true, with_active_workflow: true)

FactoryBot.create(:permission_template_access,
                  :deposit,
                  permission_template: permission_template,
                  agent_type: 'user',
                  agent_id: admin_user.user_key)

# collection to add works to
main_collection = FactoryBot.create(:public_collection, with_permission_template: permission_template)

# other collections
4.times do
  FactoryBot.create(:public_collection, with_permission_template: permission_template)
end

# private works with specific configurations - will need to log in as admin to see them
FactoryBot.create(:work_with_image_files, user: admin_user, title: ["A Work with an Image File"])
FactoryBot.create(:embargoed_work, user: admin_user, title: ["An Embargoed Work"])
FactoryBot.create(:work_with_one_file, user: admin_user, title: ["A Work with a file"])
FactoryBot.create(:work_with_file_and_work, user: admin_user, title: ["A Work with a file and work"])
FactoryBot.create(:work_with_files, user: admin_user, title: ["A Work with files"])
FactoryBot.create(:work_with_one_child, user: admin_user, title: ["A Work with one child"])
FactoryBot.create(:work_with_two_children, user: admin_user, title: ["A Work with two children"])

# public GwWorks with metadata
5.times do |i|
  FactoryBot.create(:public_work, 
                    user: admin_user, 
                    admin_set: gw_etds_admin_set,
                    title: ["Test Public ETD with metadata #{i}"],
                    gw_affiliation: ["Department of Testing", "Department of Quality Control", "Scholarly Technology Group"],
                    resource_type: [["Research Paper", "Article", "Archival Work"].sample],
                    creator: ["Professor Goodtests"],
                    contributor: ["Assistant Badtests", "Another Collaborator"],
                    description: ["A work for testing with metadata"],
                    abstract: Faker::Lorem.paragraphs(number: 1),
                    keyword: ["Testing", "Examining", "Prodding"],
                    license: ["http://www.europeana.eu/portal/rights/rr-r.html"], 
                    rights_statement: ["http://rightsstatements.org/vocab/InC/1.0/"], 
                    publisher: ["A Pretty Cool Publisher"], 
                    date_created: [rand(1900..2010).to_s], 
                    subject: ["Automated Testing"], 
                    language: ["English"],
                    member_of_collections: [main_collection]
                    )
end

# public GwJournalIssues
5.times do |i|
  FactoryBot.create(:public_journal_issue, 
                    user: admin_user, 
                    admin_set: gw_etds_admin_set,
                    title: ["Test Public GW Journal Issue with Metadata #{i}"],
                    gw_affiliation: ["Department of Testing", "Department of Quality Control", "Scholarly Technology Group"],
                    resource_type: ["Journal Issue"],
                    creator: ["Professor Goodtests"],
                    contributor: ["Assistant Badtests", "Another Collaborator"],
                    description: ["A work for testing with metadata"],
                    abstract: Faker::Lorem.paragraphs(number: 1),
                    keyword: ["Testing", "Examining", "Prodding"],
                    license: ["http://www.europeana.eu/portal/rights/rr-r.html"], 
                    rights_statement: ["http://rightsstatements.org/vocab/InC/1.0/"], 
                    publisher: ["A Pretty Cool Publisher"], 
                    date_created: [rand(1900..2010).to_s], 
                    subject: ["Automated Testing"], 
                    language: ["English"],
                    issue: [rand(1..3).to_s],
                    volume: [rand(1..3).to_s]
                    )
end

# public ETDs
5.times do |i|
  FactoryBot.create(:public_etd, 
                    user: admin_user, 
                    admin_set: gw_etds_admin_set,
                    title: ["Test Public GW Jouranl Issue with metadata #{i}"],
                    gw_affiliation: ["Department of Testing", "Department of Quality Control", "Scholarly Technology Group"],
                    resource_type: ["Journal Issue"],
                    creator: ["Professor Goodtests"],
                    contributor: ["Assistant Badtests", "Another Collaborator"],
                    description: ["A work for testing with metadata"],
                    abstract: Faker::Lorem.paragraphs(number: 1),
                    keyword: ["Testing", "Examining", "Prodding"],
                    license: ["http://www.europeana.eu/portal/rights/rr-r.html"], 
                    rights_statement: ["http://rightsstatements.org/vocab/InC/1.0/"], 
                    publisher: ["A Pretty Cool Publisher"], 
                    date_created: [rand(1900..2010).to_s], 
                    subject: ["Automated Testing"], 
                    language: ["English"],
                    degree: "Ph.D",
                    advisor: ["Doctor Advisor"],
                    committee_member: ["Committee Member 1", "Committee Member 2"]
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