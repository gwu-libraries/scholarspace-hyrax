# Implementation of a modified Dublin Core OAI format for electronic theses/disserations
# Based on example here: https://github.com/nims-dpfc/nims-hyrax/blob/d8b6e6277467ba384d8b9d73b2fc0d9aa5213403/hyrax/app/models/metadata/jpcoar.rb
class Metadata::DublinCoreEtd < OAI::Provider::Metadata::DublinCore

    def initialize
        # Use the original DublinCore implementation from the ruby_oai gem
        # Just update the prefix
        super
        @prefix = 'oai_dc_etd'
    end
end