FactoryBot.define do
  factory :gw_work do
    id { Noid::Rails::Service.new.mint }
    title { [Faker::Book.title] }
    visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  end
end