require 'rails_helper'

RSpec.describe "View works via the UI" do

  let(:solr) { Blacklight.default_index.connection }
  let(:admin_set) { FactoryBot.create(:admin_set) }

  let(:basic_user) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:content_admin_user) { FactoryBot.create(:content_admin_user) }

  let(:public_work) { FactoryBot.create(:gw_work, 
                                        admin_set: admin_set, 
                                        visibility: "public",
                                        user: admin_user) }
  let(:auth_only_work) { FactoryBot.create(:gw_work, 
                                        admin_set: admin_set, 
                                        visibility: "authenticated",
                                        user: admin_user) }
  let(:private_work) { FactoryBot.create(:gw_work, 
                                        admin_set: admin_set, 
                                        visibility: "private",
                                        user: admin_user) }


  before do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")

    [public_work, auth_only_work, private_work].map { |work| solr.add(work.to_solr) }

    solr.commit
  end

  after do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")
    solr.commit
  end

  context 'as a non-logged in user' do
    it 'can view public works' do
      visit "/concern/gw_works/#{public_work.id}"
      expect(page).to have_content(public_work.title.first)
    end

    it 'cannot view private works' do
      visit "/concern/gw_works/#{private_work.id}"
      expect(page).to_not have_content(private_work.title.first)
    end

    it 'cannot view authenticated works' do
      visit "/concern/gw_works/#{auth_only_work.id}"
      expect(page).to_not have_content(auth_only_work.title.first)
    end
  end

  context 'as a GW Community member (authenticated, non-admin, non-content-admin)' do
    before :each do
      sign_in_user(basic_user)
    end

    it 'can view public works' do
      visit "/concern/gw_works/#{public_work.id}"
      expect(page).to have_content(public_work.title.first)
    end

    it 'cannot view private works created by others' do
      visit "/concern/gw_works/#{private_work.id}"
      expect(page).to_not have_content(private_work.title.first)
      expect(page).to have_content("The page you have tried to access is private")
    end

    it 'can view authenticated works' do
      visit "/concern/gw_works/#{auth_only_work.id}"
      expect(page).to have_content(auth_only_work.title.first)
    end

  end

  context 'as a GW librarian (content-admin user)' do
    before :each do
      sign_in_user(content_admin_user)
    end

    it 'can view public works' do
      visit "/concern/gw_works/#{public_work.id}"
      expect(page).to have_content(public_work.title.first)
    end

    it 'cannot view a private work created by others' do
      visit "/concern/gw_works/#{private_work.id}"
      expect(page).to_not have_content(private_work.title.first)
    end

    it 'can view authenticated works' do
      visit "/concern/gw_works/#{auth_only_work.id}"
      expect(page).to have_content(auth_only_work.title.first)
    end
  end

  context 'as a GW library admin (admin user)' do
    before :each do
      sign_in_user(admin_user)
    end

    it 'can view public works' do
      visit "/concern/gw_works/#{public_work.id}"
      expect(page).to have_content(public_work.title.first)
    end

    it 'can view their own private work' do
      visit "/concern/gw_works/#{private_work.id}"
      expect(page).to have_content(private_work.title.first)
    end

    it 'can view authenticated works' do
      visit "/concern/gw_works/#{auth_only_work.id}"
      expect(page).to have_content(auth_only_work.title.first)
    end
  end
end