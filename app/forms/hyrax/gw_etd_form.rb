# Generated via
#  `rails generate hyrax:work GwEtd`
module Hyrax
#  class GwEtdForm < Hyrax::Forms::WorkForm
  class GwEtdForm < GwWorkForm
    self.model_class = ::GwEtd
    self.terms += [:degree]

    def secondary_terms
      super + [:degree]
    end
  end
end
