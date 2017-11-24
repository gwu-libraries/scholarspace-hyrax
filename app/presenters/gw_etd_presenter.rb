class GwEtdPresenter < GwWorkPresenter
  delegate :gw_affiliation, to: :solr_document
  delegate :degree, :advisor, :committee_member, to: :solr_document

  def permanent_url
    "https://scholarspace-etd.library.gwu.edu/etd/#{id}"
  end
end
