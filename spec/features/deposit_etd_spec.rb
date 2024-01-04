require 'spec_helper'

RSpec.describe 'Deposit through dashboard' do

  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:default_admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }
  let(:permission_template) { FactoryBot.create(:permission_template, with_admin_set: true, with_active_workflow: true) }
  let(:admin_set_collection_type) { Hyrax::CollectionType.find_or_create_admin_set_type }
  let(:user_collection_type) { Hyrax::CollectionType.find_or_create_default_collection_type }

  let(:pdf_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'hamlet.pdf')) }
  let!(:uploaded_pdf) { Hyrax::UploadedFile.create(file: pdf_file, user: admin_user) }

  let(:jpeg_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'shakespeare.jpeg')) }
  let!(:uploaded_jpeg) { Hyrax::UploadedFile.create(file: jpeg_file, user: admin_user) }

  let(:pptx_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'book report.pptx')) }
  let!(:uploaded_pptx) { Hyrax::UploadedFile.create(file: pptx_file, user: admin_user) }

  let(:tif_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'galaxy.tif')) }
  let!(:uploaded_tif) { Hyrax::UploadedFile.create(file: tif_file, user: admin_user) }

  let(:xml_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'othello.xml')) }
  let!(:uploaded_xml) { Hyrax::UploadedFile.create(file: xml_file, user: admin_user) }

  let(:txt_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'romeo_and_juliet.txt')) }
  let!(:uploaded_txt) { Hyrax::UploadedFile.create(file: txt_file, user: admin_user) }

  let(:wav_file) { File.open(File.join(Rails.root, 'spec', 'fixtures', 'public_etds', 'sorry_dave.wav')) }
  let!(:uploaded_wav) { Hyrax::UploadedFile.create(file: wav_file, user: admin_user) }

  context 'as an admin user' do
    before do
      visit "/users/sign_in"

      fill_in("user_email", with: admin_user.email)
      fill_in("user_password", with: admin_user.password)
      click_button("Log in")

      visit new_hyrax_gw_etd_path
    end

    it 'can deposit a pdf' do

      fill_in('gw_etd_title', with: "This is a title")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", "#{Rails.root}/spec/fixtures/public_etds/hamlet.pdf", visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is a title")
    end
  end

  context 'as a content-admin user' do

  end
end