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

    # Return All collections
    def collections
        Hyrax::CollectionsService.new(self).search_results
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        []
    end
end
