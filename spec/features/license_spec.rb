require 'rails_helper'

RSpec.describe "View and edit license field" do

  let(:solr) { Blacklight.default_index.connection }
  let(:admin_set) { FactoryBot.create(:admin_set) }

  let(:content_admin_user) { FactoryBot.create(:content_admin) }

  let(:work_with_license) { FactoryBot.create(:public_work, 
                                        admin_set: admin_set, 
                                        user: content_admin_user) }
  
  let(:another_license_value) { Hyrax::QaSelectService.new('licenses').select_active_options.first.first }

 before do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")

    solr.add(work_with_license.to_solr)

    solr.commit
  end

  after do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")
    solr.commit
  end

    context 'as a user looking at a work bearing a license' do
        it 'can view the license field' do
            visit "/concern/gw_works/#{work_with_license.id}"
            expect(page).to have_content(work_with_license.license.first)
        end
    end
    context 'as a content-admin user' do
        before :each do
          sign_in_user(content_admin_user)
        end

        it 'can edit the work containing the license field' do
          visit "/concern/gw_works/#{work_with_license.id}/edit"
          page.select another_license_value, :from => "gw_work_license"
          page.click_on("Save changes")
          expect(page).to have_content(another_license_value)
        end
    end

end
