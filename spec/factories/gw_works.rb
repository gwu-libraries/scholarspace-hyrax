FactoryBot.define do
  factory :gw_work do
    id { Noid::Rails::Service.new.mint }
    title { [Faker::Book.title] }

    transient do
      visibility { "public" }
      user { nil }
    end

    after :create do |work, options|
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC if options.visibility == "public"
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE if options.visibility == "private"
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED if options.visibility == "authenticated"
    end
  end
end