# frozen_string_literal: true

FactoryBot.define do
  factory :etd, aliases: [:gw_etd, :private_etd], class: 'GwEtd' do
    transient do
      user { FactoryBot.create(:user) }
      # Set to true (or a hash) if you want to create an admin set
      with_admin_set { false }
    end

    # It is reasonable to assume that a work has an admin set; However, we don't want to
    # go through the entire rigors of creating that admin set.
    before(:create) do |work, evaluator|
      if evaluator.with_admin_set
        attributes = {}
        attributes[:id] = work.admin_set_id if work.admin_set_id.present?
        attributes = evaluator.with_admin_set.merge(attributes) if evaluator.with_admin_set.respond_to?(:merge)
        admin_set = create(:admin_set, attributes)
        work.admin_set_id = admin_set.id
      end
    end

    after(:create) do |work, _evaluator|
      work.save! if work.try(:member_of_collections) && work.member_of_collections.present?
    end

    title { ["Test title"] }

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key) if work.try(:apply_depositor_metadata, evaluator.user.user_key)
    end

    factory :public_etd, traits: [:public]

    trait :public do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    factory :authenticated_etd, traits: [:authenticated]

    trait :authenticated do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end
  end
end
