require 'rails_helper'


#bundle exec rspec spec/features/dashboard_spec.rb  
RSpec.describe "Dashboard page" do

  it 'redirects to the home page if the user authenticates but lacks admin privilages' do
    non_admin_user = FactoryBot.create(:user)

    sign_in_user(non_admin_user)
    
    expect(current_path).to eq(root_path)

    visit '/dashboard/my/works'

    expect(current_path).to eq(root_path)

  end

  it 'redirects authenticated, non-admin, user to homepage when visiting /notifications' do

    non_admin_user = FactoryBot.create(:user)

    sign_in_user(non_admin_user)

    visit '/notifications'

    expect(current_path).to eq(root_path)

  end

  it 'allows authenticated admin user to visit /notifications' do

    admin_user = FactoryBot.create(:admin)

    sign_in_user(admin_user)

    visit '/notifications'

    expect(current_path).to eq("/notifications")

  end

  it 'redirects authenticated, non-admin, user to homepage when visiting /importers' do

    non_admin_user = FactoryBot.create(:user)

    sign_in_user(non_admin_user)

    visit '/importers'

    expect(current_path).to eq(root_path)

  end

  it 'allows authenticated admin user to visit /importers' do

    admin_user = FactoryBot.create(:admin)

    sign_in_user(admin_user)

    visit '/importers'

    expect(current_path).to eq("/importers")

  end

  it 'redirects authenticated, non-admin, user to homepage when visiting /exporters' do

    non_admin_user = FactoryBot.create(:user)

    sign_in_user(non_admin_user)

    visit '/exporters'

    expect(current_path).to eq(root_path)

  end

  it 'allows authenticated admin user to visit /exporters' do

    admin_user = FactoryBot.create(:admin)

    sign_in_user(admin_user)

    visit '/exporters'

    expect(current_path).to eq("/exporters")

  end

  it 'displays all admin controls when logged in as an admin user' do
    admin_user = FactoryBot.create(:admin)

    sign_in_user(admin_user)

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
    content_admin_user = FactoryBot.create(:content_admin)

    sign_in_user(content_admin_user)

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