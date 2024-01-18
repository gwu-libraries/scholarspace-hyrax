require 'spec_helper'
require 'whenever'

RSpec.describe "Schedule crontab" do

  it 'generates crontab to run sitemap generate job at 12:30 am' do
    expected = "30 0 * * * /bin/bash -l -c 'cd /opt/scholarspace/scholarspace-hyrax && RAILS_ENV=test bundle exec rake gwss:sitemap_queue_generate --silent'"
    actual = Whenever::JobList.new(file: Rails.root.join("config", "schedule.rb").to_s).generate_cron_output.strip

    expect(actual).to eq(expected)
  end

end