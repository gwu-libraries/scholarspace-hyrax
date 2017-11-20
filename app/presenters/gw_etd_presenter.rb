class GwEtdPresenter < GwWorkPresenter
  delegate :gw_affiliation, to: :solr_document
  delegate :degree, :advisor, :committee_member, to: :solr_document
end
