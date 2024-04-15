RSpec.configure do |config|

  config.before(:suite) do
    ActiveFedora::Cleaner.clean!
  end

  config.before(:each) do
    ActiveFedora::Cleaner.clean!
  end

  config.after(:each) do
    ActiveFedora::Cleaner.clean!
  end

end