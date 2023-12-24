require 'rails_helper'
require Rails.root.join("spec", "support", "sample_solr_documents")

RSpec.describe 'catalog page' do

  let(:solr) { Blacklight.default_index.connection }
  let(:sonnets) { [SONNET_2, SONNET_1, SONNET_3] }

  before do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")

    sonnets.map {|sonnet| solr.add(sonnet) }

    solr.commit
  end

  after do
    ActiveFedora::Cleaner.clean!
    solr.delete_by_query("*:*")
    solr.commit
  end

  it 'defaults to showing results in order of most recent upload to least recently upload' do
    visit search_catalog_path

    expect("Sonnet 3").to appear_before("Sonnet 2")
    expect("Sonnet 2").to appear_before("Sonnet 1")
  end

  it 'can order results by least recent upload to most recent upload' do
    visit search_catalog_path

    within "#sort-dropdown" do
      within ".dropdown-menu" do
        click_on "date uploaded ▲"
      end
    end
    
    expect("Sonnet 1").to appear_before("Sonnet 2")
    expect("Sonnet 2").to appear_before("Sonnet 3")
  end

  it 'can order results by most recent modification to least recent modification' do
    visit search_catalog_path

    within "#sort-dropdown" do
      within ".dropdown-menu" do
        click_on "date modified ▼"
      end
    end

    expect("Sonnet 3").to appear_before("Sonnet 2")
    expect("Sonnet 2").to appear_before("Sonnet 1")
  end

  it 'can order results by least recent modification to most recent modification' do
    visit search_catalog_path

    within "#sort-dropdown" do
      within ".dropdown-menu" do
        click_on "date modified ▲"
      end
    end

    expect("Sonnet 1").to appear_before("Sonnet 2")
    expect("Sonnet 2").to appear_before("Sonnet 3")
  end

  xit 'defaults to displaying 10 items per page' do
    # need factorybot for solr items
  end

  xit 'can show 20 items per page' do
    # need factorybot for solr items
  end

  xit 'can show 50 items per page' do
    # need factorybot for solr items
  end

  xit 'can show 100 items per page' do
    # need factorybot for solr items
  end

end