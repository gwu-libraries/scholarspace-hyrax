FactoryBot.define do 
  factory :GwEtd do
    depositor {}
    title { ["Test Title"] }
    description { ["test description"] }
    creator { ['Shakespeare'] }
    keyword { ['Test', 'Authenticated'] }
    rights_statement { ['http://rightsstatements.org/vocab/InC/1.0/'] }
    resource_type { ['Article'] }
    admin_set_id {}
    gw_affiliation {}
    date_uploaded {}
    date_modified {}

    after :create do |etd|
      work = GwEtd.where(id: etd.id).first
      depositor = User.where(id: etd.depositor).first
      actor = Hyrax::CurationConcern.actor
      options = { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      actor_environment = Hyrax::Actors::Environment.new(work, Ability.new(depositor), options)
      actor.create(actor_environment)
    end
  end
end