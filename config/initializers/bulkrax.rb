# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  # WorkType to use as the default if none is specified in the import
  # Default is the first returned by Hyrax.config.curation_concerns, stringified
  config.default_work_type = "GwWork"

  # Factory Class to use when generating and saving objects
  config.object_factory = Bulkrax::ObjectFactory
  # Use this for a Postgres-backed Valkyrized Hyrax
  # config.object_factory = Bulkrax::ValkyrieObjectFactory
  
  # Queue name for imports
  config.ingest_queue_name = :import

  # Path to store pending imports
  # config.import_path = 'tmp/imports'

  # Path to store exports before download
  # config.export_path = 'tmp/exports'

  # Server name for oai request header
  # config.server_name = 'my_server@name.com'

  # NOTE: Creating Collections using the collection_field_mapping will no longer be supported as of Bulkrax version 3.0.
  #       Please configure Bulkrax to use related_parents_field_mapping and related_children_field_mapping instead.
  # Field_mapping for establishing a collection relationship (FROM work TO collection)
  # This value IS NOT used for OAI, so setting the OAI parser here will have no effect
  # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
  # The default value for CSV is collection
  # Add/replace parsers, for example:
  # config.collection_field_mapping['Bulkrax::RdfEntry'] = 'http://opaquenamespace.org/ns/set'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }

  config.field_mappings['Bulkrax::CsvParser'] = {
    # Setting source_identifier: true makes bulkrax_identifier a mandatory field,
    # so it MUST be present in the CSV row for EVERY item (regardless of type, so this includes FileSets as well)
    # 
    # from Hyrax::BasicMetadata
    'label' => { from: ['label'], split: true },
    'relative_path' => { from: ['relative_path'], split: true },
    'import_url' => { from: ['import_url'], split: true },
    'resource_type' => {from: ['resource_type'], split: true },
    'creator' => { from: ['creator'], split: true },
    'contributor' => { from: ['contributor'], split: true },
    'description' => { from: ['description'], split: true },
    'abstract' => { from: ['abstract'], split: true },
    'keyword' => { from: ['keyword'], split: true },
    'license' => { from: ['license'], split: true },
    'rights_notes' => { from: ['rights_notes'], split: true },
    'rights_statement' => { from: ['rights_statement'], split: true },
    'access_right' => { from: ['access_right'], split: true },
    'publisher' => { from: ['publisher'], split: true },
    'date_created' => { from: ['date_created'], split: true },
    'subject' => { from: ['subject'], split: true },
    'language' => { from: ['language'], split: true },
    'identifier' => { from: ['identifier'], split: true },
    'based_near' => { from: ['based_near'], split: true },
    'related_url' => { from: ['related_url'], split: true },
    'bibliographic_citation' => { from: ['bibliographic_citation'], split: true },
    'source' => {from: ['source'], split: true },
    # from Hyrax::CoreMetadata
    'title' => { from: ['title'], split: true },
    'depositor' => { from: ['depositor'], split: true },
    'date_uploaded' => { from: ['date_uploaded'], split: true },
    'date_modified' => { from: ['date_modified'], split: true },
    # from Hyrax::AdminSet
    'alternative_title' => { from: ['alternative_title'], split: true },
    # from GwWork
    'bulkrax_identifier' => { from: ['bulkrax_identifier'], source_identifier: true },
    'gw_affiliation' => { from: ['gw_affiliation'], split: true },
    'doi' => { from: ['doi'], split: '\|' },
    # from GwEtd
    'degree' => { from: ['advisor'], split: true },
    'advisor' => { from: ['advisor'], split: true },
    'committee_member' => { from: ['committee_member'], split: true },
    # from GwJournalIssue
    'proquest_zipfile' => {from: ['proquest_zipfile'], split: true },
    'volume' => {from: ['volume'], split: true },
    'issue' => {from: ['issue'], split: true },
    # needed for Bulkrax
    'file' => { from: ['file'], split: '\;' },
    'parents' => { from: ['parents'], split: '\;', related_parents_field_mapping: true },
  }

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }
  #
  #   e.g. to import parent-child relationships
  #   config.field_mappings['Bulkrax::CsvParser']['parents'] = { from: ['parents'], related_parents_field_mapping: true }
  #   config.field_mappings['Bulkrax::CsvParser']['children'] = { from: ['children'], related_children_field_mapping: true }
  #   (For more info on importing relationships, see Bulkrax Wiki: https://github.com/samvera-labs/bulkrax/wiki/Configuring-Bulkrax#parent-child-relationship-field-mappings)
  #
  # #   e.g. to add the required source_identifier field
  #   #   config.field_mappings["Bulkrax::CsvParser"]["source_id"] = { from: ["old_source_id"], source_identifier: true, search_field: 'source_id_sim' }
  # If you want Bulkrax to fill in source_identifiers for you, see below

  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # Should Bulkrax make up source identifiers for you? This allow round tripping
  # and download errored entries to still work, but does mean if you upload the
  # same source record in two different files you WILL get duplicates.
  # It is given two aruguments, self at the time of call and the index of the reocrd
  #    config.fill_in_blank_source_identifiers = ->(parser, index) { "b-#{parser.importer.id}-#{index}"}
  # or use a uuid
  # config.fill_in_blank_source_identifiers = ->(parser, index) { SecureRandom.uuid }

  # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
  # config.reserved_properties += ['my_field']

  # List of Questioning Authority properties that are controlled via YAML files in
  # the config/authorities/ directory. For example, the :rights_statement property
  # is controlled by the active terms in config/authorities/rights_statements.yml
  # Defaults: 'rights_statement' and 'license'
  # config.qa_controlled_properties += ['my_field']

  # Specify the delimiter regular expression for splitting an attribute's values into a multi-value array.
  #config.multi_value_element_split_on = /\s*[:;|]\s*/.freeze
  config.multi_value_element_split_on = ';'.freeze

  # Specify the delimiter for joining an attribute's multi-value array into a string.  Note: the
  # specific delimeter should likely be present in the multi_value_element_split_on expression.
  config.multi_value_element_join_on = ' | '
end

# Sidebar for hyrax 3+ support
# rubocop:disable Style/IfUnlessModifier
if Object.const_defined?(:Hyrax) && ::Hyrax::DashboardController&.respond_to?(:sidebar_partials)
  Hyrax::DashboardController.sidebar_partials[:repository_content] << "hyrax/dashboard/sidebar/bulkrax_sidebar_additions"
end
