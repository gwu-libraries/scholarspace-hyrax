class GwWorkPresenter < Hyrax::WorkShowPresenter
  delegate :gw_affiliation, to: :solr_document
end
