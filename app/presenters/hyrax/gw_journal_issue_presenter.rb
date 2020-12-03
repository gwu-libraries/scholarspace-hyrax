# Generated via
#  `rails generate hyrax:work GwJournalIssue`
module Hyrax
  class GwJournalIssuePresenter < GwWorkPresenter
    delegate :gw_affiliation, :doi, :bibliographic_citation, 
             :volume, :issue, to: :solr_document
  end
end
