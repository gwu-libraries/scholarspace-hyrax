require 'spec_helper'

RSpec.describe "Sidekiq Dashboard Access" do

  it 'loads sidekiq dashboard for a logged in admin user' do
    admin_user = FactoryBot.create(:admin_user)

    visit "/users/sign_in"

    fill_in("user_email", with: admin_user.email)
    fill_in("user_password", with: admin_user.password)
    
    click_button("Log in")

    visit("/sidekiq")

    expect(current_path).to eq("/sidekiq")
  end

  it 'redirects users to sign-in page if not logged in as admin' do
    visit("/sidekiq")

    expect(current_path).to eq("/users/sign_in")
  end

  it 'redirects to a 404 page if visited by logged in non-admin user' do
    non_admin_user = FactoryBot.create(:user)

    visit "/users/sign_in"

    fill_in("user_email", with: non_admin_user.email)
    fill_in("user_password", with: non_admin_user.password)
    
    click_button("Log in")

    visit("/sidekiq")

    expect(page).to have_content("404: Page not found")
  end

end