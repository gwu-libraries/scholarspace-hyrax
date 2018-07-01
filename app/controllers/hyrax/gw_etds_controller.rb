# Generated via
#  `rails generate hyrax:work GwEtd`

module Hyrax
  class GwEtdsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::GwEtd
    self.show_presenter = Hyrax::GwEtdPresenter
  end
end
