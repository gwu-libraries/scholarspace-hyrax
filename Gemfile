source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.8.1'
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.3.0"
# Use pg as the production database for Active Record
gem 'pg'
# Use sitemap
# See https://github.com/viseztrance/rails-sitemap
gem 'sitemap'
# Use Puma as the app server
gem 'puma', '~> 4.3'
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

gem 'hyrax', '3.5.0'

gem 'hydra-role-management'

gem 'rsolr', '>= 1.0', '< 3'

gem 'bootstrap-sass', '~> 3.0'

gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'

gem 'jquery-rails'

gem 'devise'

gem 'devise-guests', '~> 0.6'

gem 'riiif', '~> 2.0'

gem 'cookies_eu'

#gem 'bulkrax', git: 'https://github.com/samvera-labs/bulkrax.git'
gem 'bulkrax', '2.3.0'

gem 'willow_sword', github: 'notch8/willow_sword'

gem 'whenever'

gem 'sidekiq', '~>6'
# For OAI-PHM
gem 'blacklight_oai_provider', '~>6.1.1'

gem 'dotenv-rails'

gem 'recaptcha'

gem 'invisible_captcha'

# gem 'dry-monads', '< 1.5.0'

# gem 'psych', '< 4.0.0'

# gem 'tinymce-rails', '~> 5.10'

group :development, :test do
  gem 'pry'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'solr_wrapper', '>= 0.3'
  gem 'launchy'
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
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
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end
gem "ffi", "~> 1.15"
