class GwEtdPresenter < GwWorkPresenter
  delegate :gw_affiliation, to: :solr_document
  delegate :degree, :advisor, :committee_member, to: :solr_document

  def permanent_url
    Scholarspace::Application.config.permanent_url_base + "etd/#{id}"
  end
end
