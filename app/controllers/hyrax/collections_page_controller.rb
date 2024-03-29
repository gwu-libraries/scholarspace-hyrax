# frozen_string_literal: true
class Hyrax::CollectionsPageController < ApplicationController
    include Blacklight::SearchHelper
    include Blacklight::SearchContext
    include Blacklight::AccessControls::Catalog

    class_attribute :presenter_class
    self.presenter_class = Hyrax::CollectionsPagePresenter

    def index
        @presenter = presenter_class.new(collections)
    end

    private

    # Return 5 collections
    def collections(rows: 5)
        Hyrax::CollectionsService.new(self).search_results do |builder|
        builder.rows(rows)
        end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        []
    end
end
