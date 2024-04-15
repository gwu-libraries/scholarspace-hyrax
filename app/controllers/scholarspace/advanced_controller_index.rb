# Borrowed from https://github.com/OregonDigital/OD2/blob/00c0fa49918c9c5d52c24d6d1d55a0cde632d3d3/app/controllers/concerns/oregon_digital/advanced_controller_index.rb

# Ostensibly, we should be able to set the number of options that appear for each facet on the advanced search page
# in the CatalogController. I have not been able to get that to work without it also modifying the number displayed 
# in the catalog index page - but this seems to work. 

module Scholarspace

  module AdvancedControllerIndex
    def index
      blacklight_config.facet_fields.map do |_k, facet|
        # This sets the number of options for each facet shown on the advanced search page
        # If set to -1, shows all items - causes page to crash if there are too many options, such as "keywords"
        facet.limit = -1
      end

      @response = get_advanced_search_facets unless request.method == :post
      add_breadcrumb t('hyrax.controls.advanced'), 'advanced'
    end
  end

end


BlacklightAdvancedSearch::AdvancedController.prepend Scholarspace::AdvancedControllerIndex
