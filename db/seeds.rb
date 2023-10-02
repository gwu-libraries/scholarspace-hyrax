def create_admin_role
  @admin_role = Role.find_or_create_by(name: 'admin')
end

def create_default_admin_user
  @admin_user = User.create!(email: ENV['DEV_ADMIN_USER_EMAIL'], password: ENV['DEV_ADMIN_USER_PASSWORD'])
  admin_role = Role.find_or_create_by(name: 'admin')
  admin_role.users << @admin_user
end

def create_default_admin_set
  @default_admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
end

def create_collection_type(machine_id, options)
  coltype = Hyrax::CollectionType.find_by_machine_id(machine_id)
  return coltype if coltype.present?
  default_options = {
    nestable: false, discoverable: false, sharable: false, allow_multiple_membership: false,
    require_membership: false, assigns_workflow: false, assigns_visibility: false,
    participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                   { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
  }
  final_options = default_options.merge(options.except(:title))
  Hyrax::CollectionTypes::CreateService.create_collection_type(machine_id: machine_id, title: options[:title], options: final_options)
end

def create_admin_set_collection_type
  admin_set_collection_type = Hyrax::CollectionType.find_or_create_admin_set_type
end

def create_user_collection_type
  user_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
end

def create_public_collection(user, type_gid, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  create_collection(user, type_gid, id, options)
end

def create_etds_admin_set
  etds_admin_set = Hyrax::AdministrativeSet.new(title: ['ETDs'])
  etds_admin_set = Hyrax.persister.save(resource: etds_admin_set)
  creating_user = User.where(email: ENV['DEV_ADMIN_USER_EMAIL']).first
  Hyrax::AdminSetCreateService.call!(admin_set: etds_admin_set, creating_user: creating_user)
  etds_admin_set
end

def create_collection(user, type_gid, id, options)
  col = Collection.where(id: id)
  return col.first if col.present?
  col = Collection.new(id: id)
  col.attributes = options.except(:visibility)
  col.apply_depositor_metadata(user.user_key)
  col.collection_type_gid = type_gid
  col.visibility = options[:visibility]
  col.save
  Hyrax::Collections::PermissionsCreateService.create_default(collection: col, creating_user: user)
  col
end


def create_etd(user, id, options)
  work = GwEtd.where(id: id)
  return work.first if work.present?
  actor = Hyrax::CurationConcern.actor
  attributes_for_actor = options
  work = GwEtd.new(id: id)
  actor_environment = Hyrax::Actors::Environment.new(work, Ability.new(user), attributes_for_actor)
  actor.create(actor_environment)
  work
end

def create_public_etd(user, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  create_etd(user, id, options)
end

def create_private_etd(user, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  create_etd(user, id, options)
end

def create_authenticated_etd(user, id, options)
  options[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
  create_etd(user, id, options)
end

def create_content_admin_role
  @content_admin_role = Role.find_or_create_by(name: 'content-admin')
end

def create_content_admin_user
  @content_admin_user = User.create!(email: "content-admin@example.com", password: "password")
  content_admin_role = Role.find_or_create_by(name: "content-admin")
  content_admin_role.users << @content_admin_user
end

# --------------

require 'active_fedora/cleaner'
ActiveFedora::Cleaner.clean!

# -- Creating admin role and user
create_admin_role
create_default_admin_user

# -- Creating default admin sets, admin set collection type, and user collection type --
create_default_admin_set
create_admin_set_collection_type
create_user_collection_type

# -- Creating the ETDs admin set
@etds_admin_set = create_etds_admin_set

# -- Creating a content-admin role and user
create_content_admin_role
create_content_admin_user

# -- Creating a "journal" collection type --
@journal_gid = create_collection_type('journal', 
  title: 'Journal', 
  description: 'This is a sample collection that can be found.', 
  discoverable: true).to_global_id

# -- Creating a journal collection (GW Undergraduate Review) --
@journal_collection = create_public_collection(@content_admin_user,
                                              @journal_gid, 
                                              'gwur', 
                                              title: ['GW Undergraduate Review'], 
                                              description: ['Wow it is a discoverable journal.'])



# -- Setting the banner and logo of the journal collection
banner_file = File.open('spec/fixtures/branding/gwur/banner/banner_2_gwur.png')
logo_file = File.open('spec/fixtures/branding/gwur/logo/gwur_logo.png')

branding_uploads = [banner_file, logo_file].map {|file| Hyrax::UploadedFile.create(user: @content_admin, file: file)}

banner_uploaded = Hyrax::UploadedFile.first
banner_info = CollectionBrandingInfo.new(
  collection_id: @journal_collection.id,
  filename: "GWUR_banner.png",
  role: "banner",
).save banner_uploaded.file_url

logo_uploaded = Hyrax::UploadedFile.last
logo_info = CollectionBrandingInfo.new(
  collection_id: @journal_collection.id,
  filename: "GWUR_logo.png",
  role: "logo",
).save logo_uploaded.file_url

# -- Creating ETDs as @content-user, attaching files from /spec/fixtures/journal_collection, and adding
# -- the newly created ETDs to the "GW Undergraduate Review" collection

journal_uploads = []
journal_etds = []

Dir[File.join(Rails.root, 'spec', 'fixtures', 'journal_collection', '*')].each_with_index do |file_path, index|
  file = File.open(file_path)
  title = file_path.split('/').last.split('.').first.titleize
  file_type = file_path.split('/').last.split('.').last.upcase

  journal_uploads << Hyrax::UploadedFile.create(user: @content_admin,
                                                file: file)

  journal_etds << create_public_etd(@content_admin_user,
                                    "journal_etd_#{index}",
                                    title: [title],
                                    description: ["This is a test public ETD"],
                                    creator: ["William Shakespeare"],
                                    keyword: ["Test", "Public", "#{file_type}"],
                                    rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                    publisher: ["A Fake Publisher Inc"],
                                    language: ["English"],
                                    contributor: ["Batman"],
                                    gw_affiliation: ["Student Organization"],
                                    advisor: ["Batman"],
                                    resource_type: ["Article"])

  AttachFilesToWorkJob.perform_now(journal_etds[index], [journal_uploads[index]])
end

journal_etds.each do |j_etd|
  j_etd.member_of_collections << @journal_collection
  j_etd.save
end

# -- taking the last ETD created and featuring it
@featured_work = FeaturedWork.new(work_id: journal_etds.last.id).save

# -- creating public ETDs from files in spec/fixtures/public_etds --
# -- these should be visible on main page and search without logging in --

public_uploads = []
public_etds = []

Dir[File.join(Rails.root, 'spec', 'fixtures', 'public_etds', '*')].each_with_index do |file_path, index|
  file = File.open(file_path)
  title = file_path.split('/').last.split('.').first.titleize
  file_type = file_path.split('/').last.split('.').last.upcase

  public_uploads << Hyrax::UploadedFile.create(user: @admin_user,
                                                file: file)

  public_etds << create_public_etd(@admin_user,
                                  "public_etd_#{index}",
                                  title: [title],
                                  description: ["This is a test public ETD"],
                                  creator: ["William Shakespeare"],
                                  keyword: ["Test", "Public", "#{file_type}"],
                                  rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                  publisher: ["A Fake Publisher Inc"],
                                  language: ["English"],
                                  contributor: ["Batman"],
                                  gw_affiliation: [""],
                                  advisor: ["Batman"],
                                  resource_type: ["Article"])

  AttachFilesToWorkJob.perform_now(public_etds[index], [public_uploads[index]])
end

# -- creating private ETDs from files in spec/fixtures/private_etds --
# -- these should be visible only if you are logged in as the default admin user --

private_uploads = []
private_etds = []

Dir[File.join(Rails.root, 'spec', 'fixtures', 'private_etds', '*')].each_with_index do |file_path, index|
  file = File.open(file_path)
  title = file_path.split('/').last.split('.').first.titleize
  file_type = file_path.split('/').last.split('.').last.upcase

  private_uploads << Hyrax::UploadedFile.create(user: @admin_user,
                                                file: file)

  private_etds << create_private_etd(@admin_user,
                                      "private_etd_#{index}",
                                      title: [title],
                                      description: ["This is a test private ETD"],
                                      creator: ["William Shakespeare"],
                                      keyword: ["Test", "Private", "#{file_type}"],
                                      rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                      resource_type: ["Article"])

  AttachFilesToWorkJob.perform_now(private_etds[index], [private_uploads[index]])
end

# -- creating authenticated ETDs from files in spec/fixtures/authenticated_etds --
# -- these should be visible only if you are logged in as a GW user --

authenticated_uploads = []
authenticated_etds = []

Dir[File.join(Rails.root, 'spec', 'fixtures', 'authenticated_etds', '*')].each_with_index do |file_path, index|
  file = File.open(file_path)
  title = file_path.split('/').last.split('.').first.titleize
  file_type = file_path.split('/').last.split('.').last.upcase

  authenticated_uploads << Hyrax::UploadedFile.create(user: @admin_user,
                                                      file: file)

  authenticated_etds << create_authenticated_etd(@admin_user,
                                                "authenticated_etd_#{index}",
                                                title: [title],
                                                description: ["This is a test authenticated GW user ETD"],
                                                creator: ["John Milton"],
                                                keyword: ["Test", "Authenticated", "#{file_type}"],
                                                rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                                resource_type: ["Article"])

  AttachFilesToWorkJob.perform_now(authenticated_etds[index], [authenticated_uploads[index]])
end

# -- Styling and content blocks

ContentBlock.find_or_create_by(name: "header_background_color").update!(value: "#FFFFFF")
ContentBlock.find_or_create_by(name: "header_text_color").update!(value: "#444444")
ContentBlock.find_or_create_by(name: "link_color").update!(value: "#28659A")
ContentBlock.find_or_create_by(name: "footer_link_color").update!(value: "#FFFFFF")
ContentBlock.find_or_create_by(name: "primary_buttom_background_color").update!(value: "#28659A")

featured_researcher_text = "Established in 2016, the GW Undergraduate Review (GWUR) is the premier publication of research from undergraduate students at George Washington University. Its mission is to promote undergraduate research on GW’s campus through events, workshops, and the annual publication of a peer-reviewed journal. GWUR is entirely student-run and is supported by the Office of the Vice Provost for Research and GW Libraries and Academic Innovation."
marketing_text = "Wow look at this, it is marketing text! This little text went to market. I don't know what is supposed to go here, sorry."
announcement_text = "This is an announcement! Hello!"

ContentBlock.find_or_create_by(name: "featured_researcher").update!(value: featured_researcher_text)
ContentBlock.find_or_create_by(name: "marketing_text").update!(value: marketing_text)

#TO-DO
# figure out how to set the works to go in the etds admin set, rather than the default admin set