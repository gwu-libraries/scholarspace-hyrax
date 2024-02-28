require 'rails_helper'

RSpec.describe "Dashboard page" do

=begin
  it 'redirects to the home page if the user authenticates but lacks admin privilages' do
    non_admin_user = FactoryBot.create(:user)
    OmniAuth.config.mock_auth[:saml] = generate_omniauth(non_admin_user)
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml] 
  
    page.driver.post '/users/auth/saml'

    page.driver.post '/users/auth/saml/callback'

    pp page.driver.response

    expect(current_path).to eq(root_path)

    OmniAuth.config.mock_auth[:saml] = nil

  end
=end

  it 'displays all admin controls when logged in as an admin user' do
    admin_user = FactoryBot.create(:admin_user)

    visit "/users/sign_in"

    fill_in("user_email", with: admin_user.email)
    fill_in("user_password", with: admin_user.password)
    
    click_button("Log in")

    within ".sidebar" do
      expect(page).to have_content("Dashboard")
      expect(page).to have_content("Your activity")
      expect(page).to have_content("Profile")
      expect(page).to have_content("Notifications")
      expect(page).to have_content("Transfers")
      expect(page).to have_content("Manage Proxies")

      expect(page).to have_content("Statistics")

      expect(page).to have_content("Collections")
      expect(page).to have_content("Works")
      expect(page).to have_content("Importers")
      expect(page).to have_content("Exporters")

      expect(page).to have_content("Review Submissions")
      expect(page).to have_content("Manage Embargoes")
      expect(page).to have_content("Manage Leases")

      expect(page).to have_content("Appearance")
      expect(page).to have_content("Collection Types")
      expect(page).to have_content("Pages")
      expect(page).to have_content("Content Blocks")
      expect(page).to have_content("Features")

      expect(page).to have_content("Workflow Roles")
    end
  end

  it 'displays all content-admin controls when logged in as a content-admin user' do
    content_admin_user = FactoryBot.create(:content_admin_user)

    visit "/users/sign_in"

    fill_in("user_email", with: content_admin_user.email)
    fill_in("user_password", with: content_admin_user.password)
    
    click_button("Log in")

    within ".sidebar" do
      expect(page).to have_content("Dashboard")
      expect(page).to have_content("Your activity")
      expect(page).to have_content("Profile")
      expect(page).to have_content("Notifications")
      expect(page).to have_content("Transfers")
      expect(page).to have_content("Manage Proxies")
      expect(page).to have_content("Collections")
      expect(page).to have_content("Works")
      expect(page).to have_content("Importers")
      expect(page).to have_content("Exporters")

      expect(page).to_not have_content("Statistics")
      expect(page).to_not have_content("Review Submissions")
      expect(page).to_not have_content("Manage Embargoes")
      expect(page).to_not have_content("Manage Leases")

      expect(page).to_not have_content("Appearance")
      expect(page).to_not have_content("Collection Types")
      expect(page).to_not have_content("Pages")
      expect(page).to_not have_content("Content Blocks")
      expect(page).to_not have_content("Features")

      expect(page).to_not have_content("Workflow Roles")
    end
  end

end