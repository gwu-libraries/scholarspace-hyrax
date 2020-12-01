# Generated via
#  `rails generate hyrax:work GwEtd`
class GwEtd < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  self.indexer = GwEtdIndexer

  validates :title, presence: { message: 'Your work must have a title.' }
  
  property :gw_affiliation, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#gwaffiliation') do |index|
    index.as :stored_searchable, :facetable
  end

  property :doi, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#doi') do |index|
    index.as :stored_searchable
  end

  property :degree, predicate: ::RDF::URI.new("http://scholarspace.library.gwu.edu/ns#degree"), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :advisor, predicate: ::RDF::URI.new("http://scholarspace.library.gwu.edu/ns#advisor") do |index|
    index.as :stored_searchable, :facetable
  end

  property :committee_member, predicate: ::RDF::URI.new("http://scholarspace.library.gwu.edu/ns#committee_member") do |index|
    index.as :stored_searchable, :facetable
  end

  include ::Hyrax::BasicMetadata
end
