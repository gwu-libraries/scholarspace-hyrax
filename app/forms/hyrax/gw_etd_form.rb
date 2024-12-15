# Generated via
#  `rails generate hyrax:work GwEtd`
module Hyrax
#  class GwEtdForm < Hyrax::Forms::WorkForm
  class GwEtdForm < GwWorkForm
    self.model_class = ::GwEtd
    self.terms += [:degree, :advisor, :committee_member, :proquest_zipfile]

    def secondary_terms
      super + [:degree, :advisor, :committee_member, :proquest_zipfile]
    end
  end
end
