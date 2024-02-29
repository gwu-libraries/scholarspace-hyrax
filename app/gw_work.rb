# Generated via
#  `rails generate hyrax:work GwWork`
class GwWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = GwWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }
  
  property :gw_affiliation, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#gwaffiliation') do |index|
    index.as :stored_searchable, :facetable
  end

  property :doi, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#doi') do |index|
    index.as :stored_searchable
  end

  include ::Hyrax::BasicMetadata
end
