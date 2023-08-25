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

# @discoverable_gid = create_collection_type('discoverable_collection_type', title: 'Discoverable', description: 'Sample collection type allowing collections to be discovered.', discoverable: true)
                    # .to_global_id

# @collection = create_public_collection(@admin_user, @discoverable_gid, 'col1', title: ['A Discoverable Collection'], description: ['Wow it is a discoverable collection.'])

# Here - have a content-admin create a collection

create_content_admin_role
create_content_admin_user

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
                                      rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/')

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
                                                rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/')

  AttachFilesToWorkJob.perform_now(authenticated_etds[index], [authenticated_uploads[index]])
end

#TO-DO
# create a content-admin user
# have the content-admin user create a user collection, add works to that collection
# figure out how to set the works to go in the etds admin set, rather than the default admin set
# set featured_researcher, marketing_text, and announcement_text