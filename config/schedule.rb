every 1.day, at: '12:30 am' do
  # the following tasks are run in parallel (not in sequence)
  rake "gwss:sitemap_queue_generate"
end
