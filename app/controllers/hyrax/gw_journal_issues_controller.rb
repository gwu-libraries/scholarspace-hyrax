# Generated via
#  `rails generate hyrax:work GwJournalIssue`
module Hyrax
  # Generated controller for GwJournalIssue
  class GwJournalIssuesController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::GwJournalIssue

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::GwJournalIssuePresenter
  end
end
