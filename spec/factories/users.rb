FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    #display_name { Faker::Name.name }

    factory :admin_user do
      after :create do |user|
        admin_role = Role.find_or_create_by(name: 'admin')
        admin_role.users << user
      end
    end

    factory :content_admin_user do
      after :create do |user|
        content_admin_role = Role.find_or_create_by(name: 'content-admin')
        content_admin_role.users << user
      end
    end
  end
end