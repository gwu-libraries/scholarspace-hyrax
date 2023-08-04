puts "\n" * 2
puts "-" * 50
puts "-" * 14 + "   seeding database   " + "-" * 14
puts "-" * 50
puts "\n" * 2

# creating and verifying 'admin' role
puts "-" * 11 + "   Creating 'admin' role   " + "-" * 12

admin_role = Role.find_or_create_by(name: 'admin')
if Role.find_by(id: admin_role.id).nil?
  abort("❌ Failed to create admin role")
else
  puts "\n✅ Admin role created successfully\n\n"
end

#creating and verifying a new user
puts "-" * 11 + "   Creating admin user   " + "-" * 12

admin_user = User.create(email: ENV['DEV_ADMIN_USER_EMAIL'], password: ENV['DEV_ADMIN_USER_PASSWORD'])
if User.find_by(id: admin_user.id).nil?
  abort("❌ Failed to create admin user")
else
  puts "\n✅ Admin user created successfully"
  puts "Email: #{ENV['DEV_ADMIN_USER_EMAIL']}"
  puts "Password: #{'*' * ENV['DEV_ADMIN_USER_PASSWORD'].length}"
  puts "\n" 
end


# Adding new  user to 'admin' role
puts "-" * 5 + "   Adding admin user to admin role   " + "-" * 5

admin_role.users << admin_user

if !admin_user.admin?
  abort("❌ Failed to add admin user to admin role")
else
  puts "\n✅ Admin user added to admin role successfully"
  puts "\n"
end

# Loading Hyrax Workflows
puts "-" * 12 + "   Loading Workflows   " + "-" * 12
Hyrax::Workflow::WorkflowImporter.load_workflows
errors = Hyrax::Workflow::WorkflowImporter.load_errors
if !errors.empty?
  abort("❌ Failed to load workflows")
else
  puts "\n✅ Workflows loaded successfully\n"
end

puts "\n"

# Creating the default admin set
puts "-" * 8 + "   Creating Default Admin Set   " + "-" * 8
default_admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
default_admin_set_id = default_admin_set.id.to_s

if AdminSet.find(default_admin_set_id).id != "admin_set/default"
  abort("❌ Failed to create default admin set")
else
  puts "\n✅ Successfully created default admin set\n"
end

# Creating admin collection type
puts "-" * 8 + "   Creating Admin Set Collection Type   " + "-" * 8
admin_collection_type = Hyrax::CollectionType.find_or_create_admin_set_type

if Hyrax::CollectionType.none? {|collection_type| collection_type.title == "Admin Set"}
  abort("❌ Failed to create Admin Set Collection Type")
else
  puts "\n✅ Successfully created Admin Set Collection Type\n"
end

# Creating user collection type
user_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type

if Hyrax::CollectionType.none? {|collection_type| collection_type.title == "User Collection"}
  abort("❌ Failed to create User Set Collection Type")
else
  puts "\n✅ Successfully created User Collection Type\n"
end

# Creating ETDs collection (admin type)
puts "-" * 8 + "   Creating ETDS Collection   " + "-" * 8
etds_collection = Hyrax::AdministrativeSet.new(id: "etds", title: "ETDs")
etds_collection = Hyrax.persister.save(resource: etds_collection)

# this is bad but functional, will fix
if AdminSet.find(etds_collection.id.id).id != "etds" 
  abort("❌ Failed to create ETDs collection")
else
  puts "\n✅ Successfully created ETDs Collection\n"
end