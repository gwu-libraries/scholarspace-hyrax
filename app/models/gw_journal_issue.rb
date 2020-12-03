# Generated via
#  `rails generate hyrax:work GwJournalIssue`
class GwJournalIssue < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = GwJournalIssueIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  property :gw_affiliation, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#gwaffiliation') do |index|
    index.as :stored_searchable, :facetable
  end

  property :doi, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#doi') do |index|
    index.as :stored_searchable
  end

  property :volume, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#volume') do |index|
    index.as :stored_searchable
  end

  property :issue, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#issue') do |index|
    index.as :stored_searchable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
