# frozen_string_literal: true
# OVERRIDE Hyrax v3.6.0 to display 3 rather than 4 recent uploads
module Hyrax
  module HomepageControllerDecorator
    def recent
      # grab any recent documents
      (_, @recent_documents) = search_service.search_results do |builder|
        builder.rows(3)
        builder.merge(sort: sort_field)
      end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      @recent_documents = []
    end
  end
end

Hyrax::HomepageController.prepend Hyrax::HomepageControllerDecorator