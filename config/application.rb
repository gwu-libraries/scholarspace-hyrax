require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scholarspace
  class Application < Rails::Application
    

      # The compile method (default in tinymce-rails 4.5.2) doesn't work when also
      # using tinymce-rails-imageupload, so revert to the :copy method
      # https://github.com/spohlenz/tinymce-rails/issues/183
      config.tinymce.install = :copy
    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    config.active_job.queue_adapter = :sidekiq

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
   
    # DWK added 05-Dec-2022 to resolve error of the form
    # "Psych::DisallowedClass (Tried to load unspecified class: ActiveSupport::HashWithIndifferentAccess"
    # Ref: https://stackoverflow.com/questions/71332602/upgrading-to-ruby-3-1-causes-psychdisallowedclass-exception-when-using-yaml-lo
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]
  end
 
end
