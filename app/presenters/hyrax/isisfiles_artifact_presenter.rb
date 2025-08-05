module Hyrax
  class IsisfilesArtifactPresenter < GwWorkPresenter
    delegate :gw_affiliation, :doi, :bibliographic_citation, to: :solr_document
    delegate :title_romanized, :contributor_romanized, 
             :corporate_contributor, :corporate_contributor_romanized,
	           :date_created_islamic, to: :solr_document

    def permanent_url
      Scholarspace::Application.config.permanent_url_base + "isisfiles_artifact/#{id}"
    end

    # scholarly? is used to determine whether or not
    # the Google Scholar meta tags are rendered
    def scholarly?
      false
    end
  end
end
