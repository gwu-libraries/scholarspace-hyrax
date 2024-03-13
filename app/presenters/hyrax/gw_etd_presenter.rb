module Hyrax
  class GwEtdPresenter < GwWorkPresenter
    delegate :gw_affiliation, :doi, :bibliographic_citation, to: :solr_document
    delegate :degree, :advisor, :committee_member, to: :solr_document

    def permanent_url
      Scholarspace::Application.config.permanent_url_base + "etd/#{id}"
    end

    # scholarly? is used to determine whether or not
    # the Google Scholar meta tags are rendered
    def scholarly?
      true
    end
  end
end
