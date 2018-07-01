# Generated via
#  `rails generate hyrax:work GwWork`

module Hyrax
  class GwWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::GwWork
    self.show_presenter = Hyrax::GwWorkPresenter
  end
end
