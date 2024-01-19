# reworking this to only create the necessary collections/roles/users for a minimally
# instance, and will move the seeding of works into a rake task

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