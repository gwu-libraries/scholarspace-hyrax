namespace :gwss  do
  # adding a logger since it got removed from our gemset
  def logger
    Rails.logger
  end

  desc "Queues a job to (re)generate the sitemap.xml"
  task "sitemap_queue_generate" => :environment do
    SitemapRegenerateJob.perform_later
  end
end
