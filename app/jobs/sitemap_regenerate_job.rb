require "rake"
Rails.application.load_tasks
# frozen_string_literal: true

class SitemapRegenerateJob < ApplicationJob
  def perform
    Rake::Task['schoolie:sitemap'].invoke
  end
end
