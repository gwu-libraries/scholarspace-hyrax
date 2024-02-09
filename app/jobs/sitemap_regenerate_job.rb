require "rake"
Rails.application.load_tasks
# frozen_string_literal: true

class SitemapRegenerateJob < ApplicationJob
  def perform
    puts 'invoking schoolie:sitemap from SitemapRegenerateJob'
    Rake::Task['schoolie:sitemap'].invoke
  end
end
