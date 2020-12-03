# Generated via
#  `rails generate hyrax:work GwJournalIssue`
module Hyrax
  # Generated form for GwJournalIssue
  class GwJournalIssueForm < GwWorkForm
    self.model_class = ::GwJournalIssue
    self.required_fields = [:title, :creator, :license, :rights_statement]
    self.terms += [:resource_type, :volume, :issue, :gw_affiliation, :doi, :bibliographic_citation]

    def secondary_terms
      super + [:volume, :issue]
    end
  end
end
