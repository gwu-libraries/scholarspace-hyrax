source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.8.1'
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.3.0"
# Use pg as the production database for Active Record
gem 'pg'
# Use Passenger as the app server
# Update this when we update the Passenger docker container base image version
gem 'passenger', '6.0.17', require: "phusion_passenger/rack_handler"
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'hyrax', '3.6.0'

gem 'hydra-role-management'

gem 'rsolr', '>= 1.0', '< 3'

gem 'bootstrap-sass', '~> 3.0'

gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'

gem 'jquery-rails'

gem 'chosen-rails'

gem 'devise'

gem 'devise-guests', '~> 0.6'

gem 'riiif', '~> 2.0'

gem 'cookies_eu'

gem 'bulkrax', '9.1.0'

gem 'whenever'

gem 'sidekiq', '~>6'
# For OAI-PHM
gem 'blacklight_oai_provider', '~>6.1.1'

gem 'dotenv-rails'

gem 'recaptcha'

gem 'invisible_captcha'

gem 'redlock', '>= 0.1.2', '< 2.0' # redis/sidekiq fix per https://github.com/samvera/hyrax/pull/5961

gem "ffi", "~> 1.15"

gem 'json-canonicalization', '0.3.1' # https://github.com/dryruby/json-canonicalization/issues/2

gem 'schoolie', '0.1.3'

gem 'prawn'
# SAML
gem 'omniauth-saml', '2.1.0'
gem 'omniauth-rails_csrf_protection'

gem 'blacklight_range_limit'

gem 'blacklight_advanced_search'

gem 'aws-sdk-s3', '~> 1'

gem 'sidekiq-failures', '~> 1'

group :development, :test do
  gem 'pry' # temporily removing, seems to break something with sidekiq in development mode
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'solr_wrapper', '>= 0.3'
  gem 'launchy'
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'simplecov', require: false
  gem 'database_cleaner'
  gem 'orderly'
end
