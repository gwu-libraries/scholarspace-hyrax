class CollectionsController < CatalogController
  
    def index
        solr_con = Blacklight.default_index.connection
        solr_result = solr_con.get 'select', :params => {:q => '{!term f=has_model_ssim}Collection'}
        @response = solr_result["response"]["docs"].select{ |doc| doc["visibility_ssi"] != "restricted" }
    end
  end