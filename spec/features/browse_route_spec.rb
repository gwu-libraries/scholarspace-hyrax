require 'rails_helper'

RSpec.describe "Browse route" do

  it 'redirects users to /catalog when visiting /browse' do
    visit "/browse"

    expect(current_path).to eq("/catalog")
  end

end