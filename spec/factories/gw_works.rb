FactoryBot.define do
  factory :gw_work do
    id { Noid::Rails::Service.new.mint }
    title { [Faker::Book.title] }
    visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  
    factory :gw_only_work do
      id { Noid::Rails::Service.new.mint }
      title { [Faker::Book.title] }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end

    factory :gw_private_work do
      id { Noid::Rails::Service.new.mint }
      title { [Faker::Book.title] }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end

  end
end