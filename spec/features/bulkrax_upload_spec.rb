require 'rails_helper'
require 'csv'

Rails.application.load_tasks

RSpec.describe "Deposit files through Bulkrax" do

  before :all do
    # remove the folder so it doesn't repeatedly add new works when ingest task is run
    @temp_dir = "#{ENV['TEMP_FILE_BASE']}/test/bulkrax_zip"
    if File.directory?(@temp_dir)
      FileUtils.rm_rf(@temp_dir)
    end

    Rake::Task["gwss:ingest_pq_etds"].invoke("#{Rails.root}/spec/fixtures/etd_zips")
  end
  
  it 'generates deposit file structure via gwss:ingest_pq_etds task' do
    expect(File.directory?(@temp_dir)).to be true
    expect(File.directory?("#{@temp_dir}/files")).to be true
    
    expect(File.directory?("#{@temp_dir}/files/etdadmin_upload_1")).to be true
    expect(File.file?("#{@temp_dir}/files/etdadmin_upload_1/Ab_gwu_0075A_16593_DATA.xml")).to be true
    expect(File.file?("#{@temp_dir}/files/etdadmin_upload_1/Ab_gwu_0075A_16593.pdf")).to be true

    expect(File.directory?("#{@temp_dir}/files/etdadmin_upload_2")).to be true
    expect(File.file?("#{@temp_dir}/files/etdadmin_upload_2/Ab_gwu_0076A_12345_DATA.xml")).to be true
    expect(File.file?("#{@temp_dir}/files/etdadmin_upload_2/Ab_gwu_0076A_12345.pdf")).to be true

    expect(File.file?("#{@temp_dir}/metadata.csv")).to be true
  end

  it 'generates accurate CSV file for import' do
    csv_rows = CSV.read("#{@temp_dir}/metadata.csv")

    headers_arr = csv_rows[0]
    print headers_arr
    expect(headers_arr).to eq(["model", "title", "creator", "contributor", "language",
                               "description", "keyword", "degree", "resource_type", "advisor", "gw_affiliation",
                               "date_created", "committee_member", "rights_statement", "license", "proquest_zipfile",
                               "bulkrax_identifier", "file", "parents", "visibility", "visibility_during_embargo",
                               "visibility_after_embargo", "embargo_release_date"])

    # check that there are five rows - one for header, one for each of the etds, one for each of the files
    expect(csv_rows.count).to eq(5)

    first_work_metadata = csv_rows[1]
    second_work_metadata = csv_rows[2]
    first_file_data = csv_rows[3]
    second_file_data = csv_rows[4]

    expect(first_work_metadata.include?("GwEtd")).to be true    
    expect(second_work_metadata.include?("GwEtd")).to be true

    expect(first_file_data.include?("embargo")).to be true
    expect(second_file_data.include?("embargo")).to be true

    expect(first_file_data.include?("restricted")).to be true
    expect(second_file_data.include?("restricted")).to be true
  end

  it 'can deposit works via bulkrax import' do
    admin_user = FactoryBot.create(:admin)
    etds_admin_set = Hyrax::AdministrativeSet.new(title: ['ETDs'])
    etds_admin_set = Hyrax.persister.save(resource: etds_admin_set)
    Hyrax::AdminSetCreateService.call!(admin_set: etds_admin_set, creating_user: admin_user)

    sign_in_user(admin_user)

    visit '/importers/new'

    fill_in('importer_name', with: "Test Bulkrax Import")
    select('ETDs', from: 'importer_admin_set_id')
    select('CSV - Comma Separated Values', from: 'importer_parser_klass')

    import_parser_radio_button_elements = page.all('//*[@id="importer_parser_fields_file_style_specify_a_path_on_the_server"]')
    import_parser_radio_button_elements.last.click
    
    import_parser_file_path_elements = page.all('//*[@id="importer_parser_fields_import_file_path"]')
    import_parser_file_path_elements.last.fill_in with: "#{@temp_dir}/metadata.csv"

    click_on("Create and Import")

    # the 'expect' statements below are not super specific, but the test will fail if any step in the deposit fails, so feels robust enough
    
    # check if both works are created
    work_1 = GwEtd.where(title: "A False Work For Testing Purposes").first
    work_2 = GwEtd.where(title: "Another False Work For Bulkrax Testing Purposes").first

    # check if both works get an embargo ID
    expect(work_1.embargo_id.present?).to be true
    expect(work_2.embargo_id.present?).to be true
  end
end
