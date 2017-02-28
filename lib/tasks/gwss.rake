namespace :gwss  do
  # adding a logger since it got removed from our gemset
  def logger
    Rails.logger
  end

  desc "(Re-)Generate the secret token"
  task generate_secret: :environment do
    include ActiveSupport
    File.open("#{Rails.root}/config/initializers/secret_token.rb", 'w') do |f|
      f.puts "#{Rails.application.class.parent_name}::Application.config.secret_key_base = '#{SecureRandom.hex(64)}'"
    end
  end
  
  desc "Queues a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    SitemapRegenerateJob.perform_later
  end
end
