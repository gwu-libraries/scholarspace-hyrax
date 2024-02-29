require 'rails_helper'

RSpec.describe "Deposit a PDF through dashboard" do

  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:pdf_path) { "#{Rails.root}/spec/fixtures/fixture_dummy.pdf" }
  let(:solr) { Blacklight.default_index.connection }
  let(:admin_set) { FactoryBot.create(:admin_set) }

  after do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")
    solr.commit
  end


  it 'cannot deposit as a non-admin user' do

    sign_in_user(user)

    visit new_hyrax_gw_etd_path

    expect(current_path).to eq(root_path)

  end

  it 'can deposit a pdf' do
    
    sign_in_user(admin_user)

    visit new_hyrax_gw_etd_path

    fill_in('gw_etd_title', with: "This is a PDF ETD")
    select('Article', from: 'gw_etd_resource_type')
    fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
    select('Attribution 4.0 International', from: 'gw_etd_license')
    select('In Copyright', from: 'gw_etd_rights_statement')

    click_link "Files"

    within "#add-files" do
      attach_file("files[]", pdf_path, visible: false)
    end
    
    find('body').click
    choose('gw_etd_visibility_open')
    check('agreement')

    click_on('Save')

    expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
    expect(page).to have_content("This is a PDF ETD")

  end

end