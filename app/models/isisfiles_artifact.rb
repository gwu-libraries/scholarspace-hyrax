class IsisfilesArtifact < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = IsisfilesArtifactIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  property :gw_affiliation, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#gwaffiliation') do |index|
    index.as :stored_searchable, :facetable
  end

  property :doi, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#doi') do |index|
    index.as :stored_searchable
  end

  property :title_romanized, predicate: ::RDF::URI.new('http://library.gwu.edu/ns#title_romanized') do |index|
    index.as :stored_searchable
  end

  property :contributor_romanized, predicate: ::RDF::URI.new('http://library.gwu.edu/ns#contributor_romanized'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :corporate_contributor, predicate: ::RDF::URI.new('http://library.gwu.edu/ns#corporate_contributor'), multiple: true do |index|
    index.as :stored_searchable
  end
  
  property :corporate_contributor_romanized, predicate: ::RDF::URI.new('http://library.gwu.edu/ns#corporate_contributor_romanized'), multiple: true do |index|
    index.as :stored_searchable
  end
  
  property :date_created_islamic, predicate: ::RDF::URI.new('http://library.gwu.edu/ns#date_islamic_romanized') do |index|
    index.as :stored_searchable
  end

  property :gw_affiliation, predicate: ::RDF::URI.new('http://scholarspace.library.gwu.edu/ns#gwaffiliation') do |index|
    index.as :stored_searchable, :facetable
  end

  property :bulkrax_identifier, predicate: ::RDF::URI("https://iro.bl.uk/resource#bulkraxIdentifier"), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
