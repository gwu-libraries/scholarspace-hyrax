# frozen_string_literal: true
# OVERRIDE Hyrax v3.6.0 to sort subcollections by title
# Fix thanks to https://github.com/scientist-softserv/palni-palci/pull/802/files
module Hyrax
  module CollectionsControllerBehaviorDecorator
    
    def load_member_subcollections
      super
      return if @subcollection_docs.blank?

      @subcollection_docs.sort_by! { |doc| doc.title.first&.downcase }
    end

    def show
      # OVERRIDE Hyrax 3.6.0 to initialize the works sort default field instead of using relevance
      params[:sort] ||= Hyrax::Collections::CollectionMemberSearchServiceDecorator::DEFAULT_SORT_FIELD
      super
    end
  end
end

Hyrax::CollectionsControllerBehavior.prepend Hyrax::CollectionsControllerBehaviorDecorator