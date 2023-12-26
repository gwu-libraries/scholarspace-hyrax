require 'rails_helper'
require 'rake'

Rails.application.load_tasks

RSpec.describe 'apply_contentblock_changes rake task' do

  before(:all) do
    Rake::Task['gwss:apply_contentblock_changes'].invoke
  end

  it 'populates "about" page with HTML after running task' do
    visit "/about"
    
    within "#headingOne" do
      expect(page).to have_content("What works may I contribute to GW ScholarSpace?")
    end
  end

  it 'populates homepage with HTML after running task' do
    visit root_path
    
    expect(page).to have_content("The George Washington University Undergraduate Review")
  end
  
  it 'populates "help" page with HTML after running task' do
    visit "/help"

    expect(page).to have_content("If you need to report a problem using GW ScholarSpace ")
  end
end