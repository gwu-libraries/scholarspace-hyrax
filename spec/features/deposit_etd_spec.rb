require 'spec_helper'

RSpec.describe 'Deposit through dashboard', js: true do

  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:default_admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }
  let(:permission_template) { FactoryBot.create(:permission_template, with_admin_set: true, with_active_workflow: true) }
  let(:admin_set_collection_type) { Hyrax::CollectionType.find_or_create_admin_set_type }
  let(:user_collection_type) { Hyrax::CollectionType.find_or_create_default_collection_type }

  let(:pdf_path) { "#{Rails.root}/spec/fixtures/public_etds/hamlet.pdf" }
  # let!(:uploaded_pdf) { Hyrax::UploadedFile.create(file: pdf_path, user: admin_user) }

  let(:jpeg_path) { "#{Rails.root}/spec/fixtures/public_etds/shakespeare.jpeg" }
  # let!(:uploaded_jpeg) { Hyrax::UploadedFile.create(file: jpeg_path, user: admin_user) }

  let(:pptx_path) { "#{Rails.root}/spec/fixtures/public_etds/book report.pptx" }
  # let!(:uploaded_pptx) { Hyrax::UploadedFile.create(file: pptx_path, user: admin_user) }

  let(:tif_path) { "#{Rails.root}/spec/fixtures/public_etds/galaxy.tif" }
  # let!(:uploaded_tif) { Hyrax::UploadedFile.create(file: tif_path, user: admin_user) }

  let(:xml_path) { "#{Rails.root}/spec/fixtures/public_etds/othello.xml" }
  # let!(:uploaded_xml) { Hyrax::UploadedFile.create(file: xml_path, user: admin_user) }

  let(:txt_path) { "#{Rails.root}/spec/fixtures/public_etds/romeo_and_juliet.txt" }
  # let!(:uploaded_txt) { Hyrax::UploadedFile.create(file: txt_path, user: admin_user) }

  let(:wav_path) { "#{Rails.root}/spec/fixtures/public_etds/sorry_dave.wav" }
  # let!(:uploaded_wav) { Hyrax::UploadedFile.create(file: wav_path, user: admin_user) }

  context 'as an admin user' do
    # before do
    #   visit "/users/sign_in"

    #   fill_in("user_email", with: admin_user.email)
    #   fill_in("user_password", with: admin_user.password)
    #   click_button("Log in")

    #   visit new_hyrax_gw_etd_path
    # end

    it 'can deposit a jpeg' do

      visit "/users/sign_in"

      fill_in("user_email", with: admin_user.email)
      fill_in("user_password", with: admin_user.password)
      click_button("Log in")
      
      visit new_hyrax_gw_etd_path

      fill_in('gw_etd_title', with: "This is a JPEG ETD")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", jpeg_path, visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is a JPEG ETD")
    end

    it 'can deposit a pdf' do
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
    
    it 'can deposit a pptx' do
      fill_in('gw_etd_title', with: "This is a PPTX ETD")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", pptx_path, visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is a PPTX ETD")
    end

    it 'can deposit a tif' do
      fill_in('gw_etd_title', with: "This is a TIF ETD")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", tif_path, visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is a TIF ETD")
    end

    it 'can deposit an XML' do
      fill_in('gw_etd_title', with: "This is an XML ETD")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", xml_path, visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is an XML ETD")
    end

    it 'can deposit a txt' do
      fill_in('gw_etd_title', with: "This is an TXT ETD")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", txt_path, visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is an XML ETD")
    end

    it 'can deposit a wav' do
      fill_in('gw_etd_title', with: "This is an WAV ETD")
      select('Article', from: 'gw_etd_resource_type')
      fill_in('gw_etd_creator', with: "Sandwich P. Kitty")
      select('Attribution 4.0 International', from: 'gw_etd_license')
      select('In Copyright', from: 'gw_etd_rights_statement')

      click_link "Files"

      within "#add-files" do
        attach_file("files[]", wav_path, visible: false)
      end
      
      find('body').click
      choose('gw_etd_visibility_open')
      check('agreement')

      click_on('Save')

      expect(page).to have_content("Your files are being processed by ScholarSpace in the background.")
      expect(page).to have_content("This is a WAV ETD")
    end
  end

end