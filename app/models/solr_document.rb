# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior


  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models. 

  use_extension( Hydra::ContentNegotiation )

  field_semantics.merge!(
    title: Solrizer.solr_name('title'),
    creator: Solrizer.solr_name('creator'),
    contributor: Solrizer.solr_name('contributor'),
    description: Solrizer.solr_name('description'),
    publisher: Solrizer.solr_name('publisher'),
    identifier: Solrizer.solr_name('doi'),
    subject: Solrizer.solr_name('keyword'),
    date: Solrizer.solr_name('date_created'),
    language: Solrizer.solr_name('language'),
    type: Solrizer.solr_name('resource_type')
  )
  def add_relator_terms(field_name, relator_term, subfield: false)
    # Returns an array of strings consisting of the SolrDocument value for the given Solr field name, along with the specified relator term and, if present, the field value in the $$Q subfield location (for Primo VE hyperlink display)
    # Using .try because the field might be nil
    field_ary = self[Solrizer.solr_name(field_name)].try(:map) do |field_value| 
      if subfield
        "#{field_value}#{relator_term}$$Q#{field_value}"
      else
        "#{field_value}#{relator_term}"
      end
    end
    field_ary
  end
  # Overriding Blacklight::::Document::SemanticFields#to_smemantic_fields
  # in order to provide custom metadata for exporting theses/dissertations
  def to_semantic_values
    @semantic_value_hash = super
    # Mapping for adding relator terms to DC fields for specific fields in the SolrDocument
    # Including standard DC field so that we don't override those values
    contributor_terms = {'contributor' => '',
                        'advisor' => ', advisor.',
                        'committee_member' => ', committee member.'
                        }
    description_terms = {'description' => '',
                        'degree' => ' (Degree).',
                        'gw_affiliation' => ' (GW Affiliation).'
                        }
    # Determine resource type
    if self[Solrizer.solr_name('resource_type')].include? 'Thesis or Dissertation'
      # Get advisors and committee members 
      contributors = contributor_terms.map do |field_name, relator_term|
        add_relator_terms(field_name, relator_term, subfield: true)
      end
      # Get degree and affiliation & add to description field  
      description = description_terms.map do |field_name, relator_term|
        add_relator_terms(field_name, relator_term)
      end
      # Add the repository identifier to the DC metadata (by default it's part of the header, but we can't apply Primo norm rules to the header)
      identifier = "#{OAI_CONFIG[:provider][:record_prefix]}:#{self['id']}"
      # Merge as new hash with existing field semantics
      # Using compact to remove any nils
      @semantic_value_hash.merge!(
        contributor: contributors.flatten.compact,
        description: description.flatten.compact,
        identifier: Array(identifier)
      )
    end
    @semantic_value_hash
  end

  def gw_affiliation
    self[Solrizer.solr_name('gw_affiliation')]
  end

  def doi
    self[Solrizer.solr_name('doi')]
  end

  def degree
    self[Solrizer.solr_name('degree')]
  end

  def advisor
    self[Solrizer.solr_name('advisor')]
  end

  def committee_member
    self[Solrizer.solr_name('committee_member')]
  end

  def volume
    self[Solrizer.solr_name('volume')]
  end

  def issue
    self[Solrizer.solr_name('issue')]
  end
end
