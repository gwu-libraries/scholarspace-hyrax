module Hyrax
  class IsisfilesArtifactForm < GwWorkForm
    self.model_class = ::IsisfilesArtifact
    self.terms += [:title_romanized, :contributor_romanized, :corporate_contributor,
                   :corporate_contributor_romanized, :date_created_islamic]
    self.required_fields = [:title, :rights_statement]

#    def secondary_terms
#      super + [:title_romanized, :contributor_romanized, :corporate_contributor,
#               :corporate_contributor_romanized, :date_created_islamic]
#    end

    def primary_terms
      [:title, :title_romanized, :identifier,
                          :description, :creator,
                          :contributor, :contributor_romanized,
                          :corporate_contributor, :corporate_contributor_romanized,
                          :subject, :keyword, :language,
                          :date_created, :date_created_islamic, :based_near,
                          :rights_statement, :license, :resource_type]
    end

    def secondary_terms
      super() - self.primary_terms
    end

  end
end
