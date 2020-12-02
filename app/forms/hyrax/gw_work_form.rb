# Generated via
#  `rails generate hyrax:work GwWork`
module Hyrax
  class GwWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::GwWork
    self.required_fields = [:title, :resource_type, :creator, :license, :rights_statement]
    self.terms += [:resource_type, :gw_affiliation, :doi, :bibliographic_citation]

    def secondary_terms
      [:gw_affiliation, :date_created,
       :description, :keyword, :doi,
       :identifier, :contributor, :publisher, :language,
       :based_near, :related_url, :bibliographic_citation]
    end
  end
end
