module GwAffiliationsService
  mattr_accessor :authority
  self.authority = Qa::Authorities::Local.subauthority_for('gw_affiliations')

  def self.select_all_options
    authority.all.map do |element|
      [element[:label], element[:id]]
    end
  end

  def self.label(id)
    authority.find(id).fetch('term')
  end

  def self.select_active_options
    active_elements.map { |e| [e[:label], e[:id]] }
  end

  def self.active?(id)
    authority.find(id).fetch('active')
  end

  def self.active_elements
    authority.all.select { |e| active?(e[:id]) }
  end
end
