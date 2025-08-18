# Generated via
#  `rails generate hyrax:work GwEtd`

module Hyrax
  class IsisfilesArtifactsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::IsisfilesArtifact
    self.show_presenter = Hyrax::IsisfilesArtifactPresenter
  end
end
