FactoryBot.define do
  factory :gw_work do
    id { Noid::Rails::Service.new.mint }
    title { [Faker::Book.title] }
    creator { [Faker::Book.author] }
    resource_type { [Hyrax::QaSelectService.new('resource_types').select_active_options.first.second] }
    license { [Hyrax::QaSelectService.new('licenses').select_active_options.last.second] }
    rights_statement { [Hyrax::QaSelectService.new('rights_statements').select_active_options.first.second] }

    transient do
      visibility { "public" }
      user { nil }
    end

    after :create do |work, options|
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC if options.visibility == "public"
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE if options.visibility == "private"
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED if options.visibility == "authenticated"

      # Add the user's ability to the work -> necessary for enabling access to Edit pages
      actor = Hyrax::CurationConcern.actor
      actor_environment = Hyrax::Actors::Environment.new(work, Ability.new(options.user), {})
      actor.create(actor_environment)
    end
  end
end