# Generated via
#  `rails generate curation_concerns:work Work`
module CurationConcerns
  class WorkForm < Sufia::Forms::WorkForm
    self.model_class = ::Work
    self.required_fields = [:title, :resource_type, :creator, :rights]

    self.terms = [:title, :creator, :gw_affiliation, :date_created,
                  :resource_type, :rights, :description, :keyword,
                  :identifier, :contributor, :publisher, :language,
                  :based_near, :related_url, :bibliographic_citation]

#    def primary_terms
#      [:title, :creator, :rights, :tag, :resource_type, :gw_affiliation]
#    end

#    def secondary_terms
#      terms - primary_terms
#    end

  end
end
