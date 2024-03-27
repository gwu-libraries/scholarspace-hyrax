# frozen_string_literal: true
module Hyrax
  module CollectionsPageControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::AccessControls::Catalog
    include Blacklight::Base

    included do
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper

      # This is needed as of BL 3.7
      copy_blacklight_config_from(::CatalogController)

      class_attribute :presenter_class,
                      :form_class,
                      :collections_search_builder_class

      self.presenter_class = Hyrax::CollectionPresenter

      # The search builder to find collections
      self.collections_search_builder_class = CollectionSearchBuilder

    end

    def index
      @curation_concern = @collection # we must populate curation_concern
      presenter
      #query_collection_members
    end

    def presenter
      @presenter ||= presenter_class.new(curation_concern, current_ability)
    end

    def curation_concern
      # Query Solr for the collection.
      # run the solr query to find the collection members
      response, _docs = search_service.search_results
      Rails.logger.warn("Inside collections page controller behavior")
      Rails.logger.warn(response)
      curation_concern = response.documents.first
      raise CanCan::AccessDenied unless curation_concern
      curation_concern
    end

    def search_service
      Hyrax::SearchService.new(config: blacklight_config, user_params: params.except(:q, :page), scope: self, search_builder_class: collections_search_builder_class)
    end

  end 
end 
