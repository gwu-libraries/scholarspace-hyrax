class GwWorkPresenter < Hyrax::WorkShowPresenter
  delegate :gw_affiliation, to: :solr_document

  def permanent_url
    "https://scholarspace-etd.library.gwu.edu/work/#{id}"
  end
end
