ActiveFedora.fedora.connection.send(:init_base_path)

seeder = ScholarspaceSeeder.new()

seeder.generate_admin_role

seeder.generate_default_admin_user

seeder.load_hyrax_workflows

seeder.generate_default_admin_set

seeder.generate_admin_set_collection_type

seeder.generate_user_collection_type

seeder.generate_etds_admin_set