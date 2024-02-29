module Hyrax
  class GwWorkPresenter < Hyrax::WorkShowPresenter
    delegate :gw_affiliation, :doi, :bibliographic_citation, to: :solr_document

    def permanent_url
      Scholarspace::Application.config.permanent_url_base + "work/#{id}"
    end

    def scholarly?
      false
    end
  end
end
