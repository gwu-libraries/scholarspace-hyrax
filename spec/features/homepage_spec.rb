require 'rails_helper'
require 'active_fedora/cleaner'

RSpec.describe 'homepage' do
  describe 'as a non-logged in user' do

    before :each do
      ActiveFedora::Cleaner.clean!

      @default_admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
      etds_admin_set = Hyrax::AdministrativeSet.new(title: ['ETDs'])
      @etds_admin_set = Hyrax.persister.save(resource: etds_admin_set)
      @admin = FactoryBot.create(:admin_user)
      Hyrax::AdminSetCreateService.call!(admin_set: etds_admin_set, creating_user: @admin)
    end

    it 'when user clicks search button with no text entered, they are taken to the search results page' do
      visit root_path

      click_button "search-submit-header"

      expect(current_path).to eq("/catalog")
    end

    it 'displays results on the catalog page in order of most recent to least recent by default' do
      etd1 = FactoryBot.create(:GwEtd,
                               description: [ "The middle work" ],
                               depositor: @admin.id,
                               admin_set_id: "admin_set/default",
                               date_uploaded: DateTime.new(2004, 10, 11),
                               date_modified: DateTime.new(2004, 10, 11))

      etd2 = FactoryBot.create(:GwEtd, 
                               description: [ "The earliest work" ],
                               depositor: @admin.id,
                               admin_set_id: "admin_set/default",
                               date_uploaded: DateTime.new(2003, 9, 10),
                               date_modified: DateTime.new(2003, 9, 10))
          
      etd3 = FactoryBot.create(:GwEtd, 
                               description: [ "The latest work" ],
                               depositor: @admin.id,
                               admin_set_id: "admin_set/default",
                               date_uploaded: DateTime.new(2005, 11, 12),
                               date_modified: DateTime.new(2005, 11, 12))
      
      visit root_path

      click_button "search-submit-header"

      expect("The earliest work").to appear_before("The middle work", only_text: true)
      expect("The middle work").to appear_before("The latest work", only_text: true)
    end
  end
end