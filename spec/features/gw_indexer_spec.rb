require 'rails_helper'

RSpec.describe "GwIndexer" do

  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:solr) { Blacklight.default_index.connection }
  let(:gw_work) { FactoryBot.create(:gw_work, 
                                    admin_set: admin_set, 
                                    visibility: "public",
                                    user: admin_user) }
  let(:solr_doc) { gw_work.to_solr }

  it 'creates a new solr document for gw work' do

    expect(solr_doc).to be_a(Hash)

    expect(solr_doc['system_create_dtsi']).to be_a String
    expect(solr_doc['system_modified_dtsi']).to be_a String
    expect(solr_doc['has_model_ssim']).to be_a ActiveTriples::Relation
    expect(solr_doc['has_model_ssim'].first).to be_a String
    expect(solr_doc[:id]).to be_a String
    expect(solr_doc['accessControl_ssim']).to be_a Array
    expect(solr_doc['accessControl_ssim'].first).to be_a String
    expect(solr_doc['title_tesim']).to be_a Array
    expect(solr_doc['title_tesim'].first).to be_a String
    expect(solr_doc['title_sim']).to be_a Array
    expect(solr_doc['title_sim'].first).to be_a String
    expect(solr_doc['isPartOf_ssim']).to be_a Array
    expect(solr_doc['isPartOf_ssim'].first).to be_a String
    expect(solr_doc['hasEmbargo_ssim']).to be_a Array
    expect(solr_doc['hasEmbargo_ssim'].first).to be_a String
    expect(solr_doc['hasLease_ssim']).to be_a Array
    expect(solr_doc['hasLease_ssim'].first).to be_a String
    expect(solr_doc['thumbnail_path_ss']).to be_a String
    expect(solr_doc['suppressed_bsi']).to be false
    expect(solr_doc['member_ids_ssim']).to be_a Array
    expect(solr_doc['member_of_collections_ssim']).to be_a Array
    expect(solr_doc['member_of_collection_ids_ssim']).to be_a Array
    expect(solr_doc['generic_type_sim']).to be_a Array
    expect(solr_doc['generic_type_sim'].first).to be_a String
    expect(solr_doc['file_set_ids_ssim']).to be_a Array
    expect(solr_doc['visibility_ssi']).to be_a String
    expect(solr_doc['visibility_ssi'].first).to be_a String
    expect(solr_doc['admin_set_sim']).to be_a ActiveTriples::Relation
    expect(solr_doc['admin_set_sim'].first).to be_a String
    expect(solr_doc['admin_set_tesim']).to be_a ActiveTriples::Relation
    expect(solr_doc['admin_set_tesim'].first).to be_a String
    expect(solr_doc['human_readable_type_sim']).to be_a String
    expect(solr_doc['human_readable_type_tesim']).to be_a String
    expect(solr_doc['read_access_group_ssim']).to be_a Array
    expect(solr_doc['read_access_group_ssim'].first).to be_a String
    expect(solr_doc['embargo_history_ssim']).to be_a ActiveTriples::Relation
    expect(solr_doc['lease_history_ssim']).to be_a ActiveTriples::Relation
    
  end

  context "date_created_isim field" do
    it 'has a date_created_isim field containing a four-digit year, when date_created is filled with four digit year' do

      gw_work_good_year = FactoryBot.create(:gw_work, 
                                            admin_set: admin_set, 
                                            visibility: "public", 
                                            date_created: ["2001"],
                                            user: admin_user)

      expect(gw_work_good_year.to_solr['date_created_isim']).to eq(2001)

    end

    it 'chooses the minimum valid four-digit year if multiple date_created values' do

      gw_work_multiple_date_created_values = FactoryBot.create(:gw_work, 
                                            admin_set: admin_set, 
                                            visibility: "public", 
                                            date_created: ["august", "4", "2009", "2005", "1999"],
                                            user: admin_user)

      expect(gw_work_multiple_date_created_values.to_solr['date_created_isim']).to eq(1999)

    end

    it 'has a nil value if no convertable dates' do

      gw_work_no_good_values = FactoryBot.create(:gw_work, 
                                            admin_set: admin_set, 
                                            visibility: "public", 
                                            date_created: ["august", "4", "garbanzo"],
                                            user: admin_user)

      expect(gw_work_no_good_values.to_solr['date_created_isim']).to eq(nil)
    end
  end
end
