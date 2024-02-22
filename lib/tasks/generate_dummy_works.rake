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

    # Check if PDF already exists at path, otherwise generate pdf
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

    # Create arrays of the file paths
    public_files = Dir[File.join(Rails.root, 'spec', 'fixtures', 'dummy_works', 'public', '*')]
    private_files = Dir[File.join(Rails.root, 'spec', 'fixtures', 'dummy_works', 'private', '*')]
    authenticated_files = Dir[File.join(Rails.root, 'spec', 'fixtures', 'dummy_works', 'authenticated', '*')]

    public_uploads = []
    public_works = []

    private_uploads = []
    private_works = []

    authenticated_uploads = []
    authenticated_works = []

    # Iterate through the file paths, create ETDs, attach files
    public_files.each_with_index do |file_path, index|
      next if GwEtd.exists?("public_work_#{index}")
      file = File.open(file_path)
      title = file_path.split('/').last.split('.').first.titleize

      public_uploads << Hyrax::UploadedFile.create(user: admin_user, file: file)
      
      public_works << create_public_etd(admin_user,
                                        "public_work_#{index}",
                                        title: [title],
                                        description: ["This is a test public ETD"],
                                        creator: ["Professor Test"],
                                        keyword: ['Test', 'Public'],
                                        rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                        publisher: ["A Fake Publisher Inc"],
                                        language: ["English"],
                                        contributor: ["Assistant Test"],
                                        gw_affiliation: [""],
                                        advisor: ["Advisor Test"],
                                        resource_type: ["Article"])
      
      AttachFilesToWorkJob.perform_now(public_works[index], [public_uploads[index]])
    end

    private_files.each_with_index do |file_path, index|
      next if GwEtd.exists?("private_work_#{index}")
      file = File.open(file_path)
      title = file_path.split('/').last.split('.').first.titleize

      private_uploads << Hyrax::UploadedFile.create(user: admin_user, file: file)
      
      private_works << create_private_etd(admin_user,
                                        "private_work_#{index}",
                                        title: [title],
                                        description: ["This is a test private ETD"],
                                        creator: ["Professor Test"],
                                        keyword: ['Test', 'Private'],
                                        rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                        publisher: ["A Fake Publisher Inc"],
                                        language: ["English"],
                                        contributor: ["Assistant Test"],
                                        gw_affiliation: [""],
                                        advisor: ["Advisor Test"],
                                        resource_type: ["Article"])
      
      AttachFilesToWorkJob.perform_now(private_works[index], [private_uploads[index]])
    end

    authenticated_files.each_with_index do |file_path, index|
      next if GwEtd.exists?("authenticated_work_#{index}")
      file = File.open(file_path)
      title = file_path.split('/').last.split('.').first.titleize

      authenticated_uploads << Hyrax::UploadedFile.create(user: admin_user, file: file)
      
      authenticated_works << create_authenticated_etd(admin_user,
                                        "authenticated_work_#{index}",
                                        title: [title],
                                        description: ["This is a test authenticated ETD"],
                                        creator: ["Professor Test"],
                                        keyword: ['Test', 'Authenticated'],
                                        rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
                                        publisher: ["A Fake Publisher Inc"],
                                        language: ["English"],
                                        contributor: ["Assistant Test"],
                                        gw_affiliation: [""],
                                        advisor: ["Advisor Test"],
                                        resource_type: ["Article"])
      
      AttachFilesToWorkJob.perform_now(authenticated_works[index], [authenticated_uploads[index]])
    end

  end 
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