# Generated via
#  `rails generate hyrax:work GwWork`
module Hyrax
  class GwWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::GwWork
    self.terms += [:resource_type]
  end
end
