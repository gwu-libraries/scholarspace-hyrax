class ScholarspaceSeeder

  def initialize()
  end

  def generate_admin_role
    admin_role = Role.find_or_create_by(name: 'admin')
    verify_admin_role(admin_role)
    admin_role
  end

  def generate_default_admin_user
    user = User.create!(email: ENV['DEV_ADMIN_USER_EMAIL'], password: ENV['DEV_ADMIN_USER_PASSWORD'])
    admin_role = Role.find_by(name: 'admin')
    admin_role.users << user
    verify_default_admin_user(user)
  end

  def load_hyrax_workflows
    Hyrax::Workflow::WorkflowImporter.load_workflows
    verify_hyrax_workflows
  end

  def generate_default_admin_set
    default_admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    Hyrax::PermissionTemplate.create!(source_id: Hyrax::AdminSetCreateService::DEFAULT_ID)
    verify_default_admin_set(default_admin_set)
    default_admin_set
  end

  def generate_admin_set_collection_type
    admin_set_collection_type = Hyrax::CollectionType.find_or_create_admin_set_type
    verify_admin_set_collection_type
    admin_set_collection_type
  end

  def generate_user_collection_type
    user_collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
    verify_user_collection_type
    user_collection_type
  end

  def generate_etds_admin_set
    etds_admin_set = Hyrax::AdministrativeSet.new(title: ['ETDs'])
    etds_admin_set = Hyrax.persister.save(resource: etds_admin_set)
    creating_user = User.where(email: ENV['DEV_ADMIN_USER_EMAIL']).first
    Hyrax::AdminSetCreateService.call!(admin_set: etds_admin_set, creating_user: creating_user)
    verify_etds_admin_set(etds_admin_set)
  end

  private

  def verify_admin_role(admin_role)
    if Role.find_by(id: admin_role.id).nil?
      abort("❌ Failed to create admin role")
    else
      puts "\n✅ Admin role created successfully\n\n"
    end
  end

  def verify_default_admin_user(user)
    if User.find_by(id: user.id).nil?
      abort("❌ Failed to create admin user")
    else
      puts "\n✅ Admin user created successfully"
      puts "Email: #{ENV['DEV_ADMIN_USER_EMAIL']}"
      puts "Password: #{'*' * ENV['DEV_ADMIN_USER_PASSWORD'].length}"
      puts "\n" 
    end
  end

  def verify_hyrax_workflows
    errors = Hyrax::Workflow::WorkflowImporter.load_errors
    if !errors.empty?
      abort("❌ Failed to load workflows")
    else
      puts "\n✅ Workflows loaded successfully\n"
    end  
  end

  def verify_default_admin_set(default_admin_set)
    default_admin_set_id = default_admin_set.id.to_s
    if AdminSet.find(default_admin_set_id).id != "admin_set/default"
      abort("❌ Failed to create default admin set")
    else
      puts "\n✅ Successfully created default admin set\n"
    end
  end

  def verify_admin_set_collection_type
    if Hyrax::CollectionType.none? {|collection_type| collection_type.title == "Admin Set"}
      abort("❌ Failed to create Admin Set Collection Type")
    else
      puts "\n✅ Successfully created Admin Set Collection Type\n"
    end
  end

  def verify_user_collection_type
    if Hyrax::CollectionType.none? {|collection_type| collection_type.title == "User Collection"}
      abort("❌ Failed to create User Set Collection Type")
    else
      puts "\n✅ Successfully created User Collection Type\n"
    end
  end

  def verify_etds_admin_set(etds_admin_set)
    if AdminSet.where(title: ["ETDs"]).first.nil?
      abort("❌ Failed to create ETDs Admin Set")
    else
      puts "\n✅ Successfully created ETDs Admin Set\n"
    end
  end

end