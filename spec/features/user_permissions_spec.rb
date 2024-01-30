require 'rails_helper'

# Permission levels:
# GW Community member - read items with "GW Community" visibility - any logged in user
# LAI Staff - read items, create works, approve works
# STG Staff - admin role, see all works

RSpec.describe "User Permissions" do
  let(:solr) { Blacklight.default_index.connection }

  let(:normal_user) { FactoryBot.create(:user) }
  let(:content_admin_user) { FactoryBot.create(:content_admin_user) }
  let(:admin_user) { FactoryBot.create(:admin_user) }

  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:public_work) { FactoryBot.create(:gw_work, admin_set: admin_set, visibility: "public") }
  let(:private_work) { FactoryBot.create(:gw_work, admin_set: admin_set, visibility: "private") }
  let(:authenticated_work) { FactoryBot.create(:gw_work, admin_set: admin_set, visibility: "authenticated") }

  before do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")

    [public_work, private_work, authenticated_work].map { |work| solr.add(work.to_solr) }

    solr.commit
  end

  after do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")
    solr.commit
  end

  context 'as a non-logged in user' do
    it 'can view public works' do
      visit "/catalog"

      expect(page).to have_content(public_work.title.first)
    end

    it 'cannot view private works' do
      visit "/catalog"

      expect(page).to_not have_content(private_work.title.first)
    end

    it 'cannot view authenticated works' do
      visit "/catalog"

      expect(page).to_not have_content(authenticated_work.title.first)
    end
  end

  context 'as a GW Community member (authenticated non-admin, non-content-admin)' do
    it 'user can be created' do
      expect(normal_user).to be_a(User)
    end

    it 'can view public works' do
      visit "/users/sign_in"
      fill_in("user_email", with: normal_user.email)
      fill_in("user_password", with: normal_user.password)
      click_button("Log in")

      visit "/catalog"

      expect(page).to have_content(public_work.title.first)
    end

    it 'can view authenticated works' do
      visit "/users/sign_in"
      fill_in("user_email", with: normal_user.email)
      fill_in("user_password", with: normal_user.password)
      click_button("Log in")

      visit "/catalog"

      expect(page).to have_content(authenticated_work.title.first)
    end

    it 'cannot view private works by another user' do
      visit "/users/sign_in"
      fill_in("user_email", with: normal_user.email)
      fill_in("user_password", with: normal_user.password)
      click_button("Log in")

      visit "/catalog"

      expect(page).to_not have_content(private_work.title.first)
    end

  end

  context 'as an LAI Staff member (content-admin)' do
    it 'content-admin user can be created' do
      expect(content_admin_user).to be_a(User)
    end

    it 'can view public works' do
      visit "/users/sign_in"
      fill_in("user_email", with: content_admin_user.email)
      fill_in("user_password", with: content_admin_user.password)
      click_button("Log in")

      visit "/catalog"

      expect(page).to have_content(public_work.title.first)
    end

    it 'can view authenticated works' do
      visit "/users/sign_in"
      fill_in("user_email", with: content_admin_user.email)
      fill_in("user_password", with: content_admin_user.password)
      click_button("Log in")

      visit "/catalog"

      expect(page).to have_content(authenticated_work.title.first)
    end
  end

  context 'as STG staff (admin)' do
    it 'admin user can be created' do
      stg_staff = FactoryBot.create(:admin_user)

      expect(stg_staff).to be_a(User)
    end
  end

end