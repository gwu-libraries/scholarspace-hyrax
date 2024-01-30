FactoryBot.define do
  factory :gw_work do
    transient do
      visibility { "public" }
    end

    id { Noid::Rails::Service.new.mint }
    title { [Faker::Book.title] }

    after :create do |work, options|
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC if options.visibility == "public"
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE if options.visibility == "private"
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED if options.visibility == "authenticated"
    end
  end
end