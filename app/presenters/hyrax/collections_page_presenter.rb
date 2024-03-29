module Hyrax
    class CollectionsPagePresenter
        attr_reader :collections

        def initialize(collections)
            @collections = collections
          end
    end
end