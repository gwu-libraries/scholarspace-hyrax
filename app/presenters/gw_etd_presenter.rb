class GwEtdPresenter < GwWorkPresenter
  delegate :gw_affiliation, to: :solr_document
  delegate :degree, to: :solr_document
end
