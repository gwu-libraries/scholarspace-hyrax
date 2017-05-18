class GwEtdPresenter < GwWorkPresenter
  delegate :degree, to: :solr_document
end
