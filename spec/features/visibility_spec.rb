require 'rails_helper'

RSpec.describe "View works via the UI" do

  let(:user) { FactoryBot.create(:user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:public_work) { FactoryBot.create(:gw_work, admin_set: admin_set, visibility: "public") }
  let(:auth_only_work) { FactoryBot.create(:gw_work, admin_set: admin_set, visibility: "authenticated") }
  let(:private_work) { FactoryBot.create(:gw_work, admin_set: admin_set, visibility: "private") }
  let(:solr) { Blacklight.default_index.connection }

  before do
    [public_work, auth_only_work, private_work].map { |work| solr.add(work.to_solr) }
    solr.commit
  end

  before :each do
    visit root_path
  end

  after do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")
    solr.commit
  end

  it 'can view a public work without authenticating' do

    within ".navigation-wrap" do
        click_on "Browse Everything"
      end
    
    expect(page).to have_content(public_work.title.first)
  end

  it 'cannot view private or restricted works' do

    within ".navigation-wrap" do
        click_on "Browse Everything"
      end
    
    expect(page).to have_no_content(private_work.title.first)

    expect(page).to have_no_content(auth_only_work.title.first)

  end

  it 'can view restricted works but not private works after authenticating' do

    sign_in_user(user)
    
    within ".navigation-wrap" do
        click_on "Browse Everything"
      end
    
    expect(page).to have_content(auth_only_work.title.first)

    expect(page).to have_no_content(private_work.title.first)

  end
end