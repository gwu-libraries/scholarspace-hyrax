require 'rake'

namespace :gwss do

  desc "Prepares new prod instance"
  task :prep_new_prod => :environment do
    abort("Please supply admin_user email as an argument") if ENV['admin_user'].nil?
    abort("Please supply admin_user password") if ENV['admin_password'].nil?
    abort("admin_user email is already taken!") if User.find_by(email: ENV['admin_user']) != nil

    admin_role = Role.find_or_create_by(name: "admin")
    content_admin_role = Role.find_or_create_by(name: "content-admin")

    admin_user = User.create(email: ENV['admin_user'], password: ENV['admin_password'])
    admin_role.users << admin_user

    default_admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    admin_set_collection_type = Hyrax::CollectionType.find_or_create_admin_set_type
    user_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
    etds_admin_set = Hyrax::AdministrativeSet.new(title: ['ETDs'])
    etds_admin_set = Hyrax.persister.save(resource: etds_admin_set)
    Hyrax::AdminSetCreateService.call!(admin_set: etds_admin_set, creating_user: admin_user)

    Rake::Task['assets:precompile'].invoke
  end

end