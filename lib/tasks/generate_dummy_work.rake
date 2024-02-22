require 'rake'

namespace :gwss do

  desc "Creates dummy works for development"
  # Takes integer arguments for number of each work type to generate
  # i.e.
  # bundle exec rails gwss:create_dummy_works public_works=2 private_works=2 authenticated_works=1
  task :create_dummy_works => :environment do
    # Sets these counts to either the argument passed in or 0 if no argument
    public_work_count = ENV['public_works'].to_i || 0
    private_work_count = ENV['private_works'].to_i || 0
    authenticated_work_count = ENV['authenticated_works'].to_i || 0

    # Finding first admin user
    admin_user = Role.find_by(name: "admin").users.first

    # Finding admin set
    admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    admin_set_collection_type = Hyrax::CollectionType.find_or_create_admin_set_type

    public_work_count.times do |index|
      file_path = Rails.root.join('spec', 'fixtures', 'dummy_works', 'public', "public_work_#{index}.pdf")
      if !File.file?(file_path)
        Prawn::Document.generate file_path do |pdf|
          pdf.text "This is public work #{index}", size: 80
        end
      end
    end

    private_work_count.times do |index|
      file_path = Rails.root.join('spec', 'fixtures', 'dummy_works', 'private', "private_work_#{index}.pdf")
      if !File.file?(file_path)
        Prawn::Document.generate file_path do |pdf|
          pdf.text "This is private work #{index}", size: 80
        end
      end
    end

    authenticated_work_count.times do |index|
      file_path = Rails.root.join('spec', 'fixtures', 'dummy_works', 'authenticated', "authenticated_work_#{index}.pdf")
      if !File.file?(file_path)
        Prawn::Document.generate file_path do |pdf|
          pdf.text "This is authenticated work #{index}", size: 80
        end
      end
    end

    public_files = Dir[File.join(Rails.root, 'spec', 'fixtures', 'dummy_works', 'public', '*')][0...public_work_count]
    private_files = Dir[File.join(Rails.root, 'spec', 'fixtures', 'dummy_works', 'private', '*')][0...private_work_count]
    authenticated_files = Dir[File.join(Rails.root, 'spec', 'fixtures', 'dummy_works', 'authenticated', '*')][0...authenticated_work_count]

    require 'pry'; binding.pry 
  end
 
end