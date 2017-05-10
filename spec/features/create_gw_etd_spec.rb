# Generated via
#  `rails generate hyrax:work GwEtd`
require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a GwEtd' do
  context 'a logged in user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      login_as user
    end

    scenario do
      visit new_curation_concerns_gw_etd_path
      fill_in 'Title', with: 'Test GwEtd'
      click_button 'Create GwEtd'
      expect(page).to have_content 'Test GwEtd'
    end
  end
end
