# frozen_string_literal: true
require 'builder'

module Hyrax
    module SolrDocument
        module DublinCoreEtd
            # Overriding certain methods from this module & adding others
            include Blacklight::Document::DublinCore
            
            def self.register_export_formats(document)
                # This method called when SolrDocument includes this extension
                document.will_export_as(:oai_dc_etd, "text/xml")
                # Call parent module's method
                super document
            end

            def get_additional_fields
                # Returns a hash mapping an additional document field to a DC field and an attribute name, such that advisor => <dc:contributor type="advisor">
                { :advisor => { :name => "contributor", :attr => "type" },
                :committee_member => { :name => "contributor", :attr => "type" },
                :degree => { :name => "description", :attr => "primo_field" },
                :gw_affiliation => { :name => "description", :attr => "primo_field" } }
            end

            def to_oai_dc_etd
                export_as("oai_dc_etd")
            end

            def export_as_oai_dc_etd 
                # Generate XML for ETD's, using basic DC with a couple of extra attributes
                # Based on Blacklight::Document::DublinCore.export_as_oai_dc_xml
                xml = Builder::XmlMarkup.new
                xml.tag!("oai_dc_etd:dc",
                # Hacky --> We're not actually using a different schema
                'xmlns:oai_dc_etd' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                'xsi:schemaLocation' => %(http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd)) do
                    addl_fields = get_additional_fields
                    # Extend the list of fields to include
                    dc_fields = dublin_core_field_names + addl_fields.keys
                    self.to_semantic_values.select { |field, values| dc_fields.include? field.to_sym }.each do |field, values|
                        Array.wrap(values).each do |v|
                            # Only use attributes if one of the special ETD fields
                            etd_field = addl_fields.fetch(field, nil)
                            if etd_field
                                tag_name = etd_field[:name]
                                attr_name = etd_field[:attr].to_sym
                                xml.tag!("dc:#{tag_name}", v, attr_name => field)
                            else
                                xml.tag! "dc:#{field}", v
                            end
                        end
                    end
                end
                xml.target!
            end
        end
    end
end
