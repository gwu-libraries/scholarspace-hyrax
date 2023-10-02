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
  use_extension(Hyrax::SolrDocument::DublinCoreEtd)
  # Do content negotiation for AF models. 

  use_extension( Hydra::ContentNegotiation )

  field_semantics.merge!(
    title: ActiveFedora.index_field_mapper.solr_name('title'),
    creator: ActiveFedora.index_field_mapper.solr_name('creator'),
    contributor: ActiveFedora.index_field_mapper.solr_name('contributor'),
    description: ActiveFedora.index_field_mapper.solr_name('description'),
    publisher: ActiveFedora.index_field_mapper.solr_name('publisher'),
    identifier: ActiveFedora.index_field_mapper.solr_name('doi'),
    subject: ActiveFedora.index_field_mapper.solr_name('keyword'),
    date: ActiveFedora.index_field_mapper.solr_name('date_created'),
    language: ActiveFedora.index_field_mapper.solr_name('language'),
    type: ActiveFedora.index_field_mapper.solr_name('resource_type'),
    advisor: ActiveFedora.index_field_mapper.solr_name('advisor'),
    committee_member: ActiveFedora.index_field_mapper.solr_name('committee_member'),
    gw_affiliation: ActiveFedora.index_field_mapper.solr_name('gw_affiliation'),
    degree: ActiveFedora.index_field_mapper.solr_name('degree')
  )
  
  self.timestamp_key = "system_create_dtsi"

  def gw_affiliation
    self[ActiveFedora.index_field_mapper.solr_name('gw_affiliation')]
  end

  def doi
    self[ActiveFedora.index_field_mapper.solr_name('doi')]
  end

  def degree
    self[ActiveFedora.index_field_mapper.solr_name('degree')]
  end

  def advisor
    self[ActiveFedora.index_field_mapper.solr_name('advisor')]
  end

  def committee_member
    self[ActiveFedora.index_field_mapper.solr_name('committee_member')]
  end

  def volume
    self[ActiveFedora.index_field_mapper.solr_name('volume')]
  end

  def issue
    self[ActiveFedora.index_field_mapper.solr_name('issue')]
  end
end
