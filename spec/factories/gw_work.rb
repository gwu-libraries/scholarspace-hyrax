require 'time'

FactoryBot.define do
  factory :gw_work do
    creation_date = Faker::Date.between(from: '1900-01-01', to: '2000-01-01').strftime("%Y-%m-%d %l:%M:%S")

    id { Faker::Alphanumeric.alphanumeric(number: 9) }
    head { [] } 
    tail { [] } 
    depositor { "admin@example.com" } 
    title { ["BEEP BEEP"] } 
    date_uploaded { creation_date } 
    date_modified { creation_date } 
    proxy_depositor { nil }
    on_behalf_of { nil }
    arkivo_checksum { nil }
    owner { nil } 
    gw_affiliation { [] } 
    doi { [] }
    alternative_title { [] } 
    label { nil }
    relative_path { nil }
    import_url { nil }
    resource_type { ["Article"] }
    creator { ["Boyd, Alex"] } 
    contributor { [] }
    description { [] }
    abstract { [] }
    keyword { [] }
    license { ["http://creativecommons.org/licenses/by/4.0/"] }
    rights_notes { [] }
    rights_statement { ["http://rightsstatements.org/vocab/InC/1.0/"] }
    access_right { [] }
    publisher { [] }
    date_created { [] }
    subject { [] } 
    language { [] }
    identifier { [] }
    based_near { [] }
    related_url { [] } 
    bibliographic_citation { [] }
    source { [] }
    access_control_id { "cdc0431d-a28c-4a31-9f0c-a1584b5c338a" }
    representative_id { nil } 
    thumbnail_id { nil }
    rendering_ids { [] } 
    admin_set_id { "admin_set/default" } 
    embargo_id { "dda26143-1e40-47c8-a2a0-2826b3184220" } 
    lease_id { "e0fa016f-9c88-4855-878e-987b521f64d4" }
  end
end