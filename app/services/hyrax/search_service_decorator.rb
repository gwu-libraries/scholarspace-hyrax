# frozen_string_literal: true
# Courtesy of https://github.com/scientist-softserv/palni-palci/blob/main/app/services/hyrax/search_service_decorator.rb
module Hyrax
  module SearchServiceDecorator
    def search_results
      # Patch to fix a bug with the blacklight_range_finder gem
      # The catalog_controller#find_range method calls this method on an instance where the @user_params are empty
      # Because of that, the builder receives empty @blacklight_params, and the fetch_specific_range_limits method on the processor change
      # fails. The range limits are included in the @params attribute, however.
      # In all other cases, we want to fall back on the @user_params attribute.
      if (respond_to?(:params) && user_params.empty?)
        builder = search_builder.with(params)
      else
        builder = search_builder.with(user_params)
      end
      builder.page = user_params[:page] if user_params[:page]
      builder.rows = (user_params[:per_page] || user_params[:rows]) if user_params[:per_page] || user_params[:rows]
      builder = yield(builder) if block_given?
      builder.merge(sort: user_params[:sort]) if user_params[:sort]
      response = repository.search(builder)
      if response.grouped? && grouped_key_for_results
        [response.group(grouped_key_for_results), []]
      elsif response.grouped? && response.grouped.length == 1
        [response.grouped.first, []]
      else
        [response, response.documents]
      end
    end
  end
end

Hyrax::SearchService.prepend Hyrax::SearchServiceDecorator