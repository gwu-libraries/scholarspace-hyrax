# frozen_string_literal: true
module Hyrax
  module Admin
    class StrategiesController < Flipflop::StrategiesController
      before_action do
        authorize! :manage, Hyrax::Feature
      end

      # TODO: we could remove this if we used an isolated engine
      def features_url
        hyrax.admin_features_path
      end

      def update
        Flipflop::FeatureSet.current.switch!(feature_key, strategy_key, enable?)
        redirect_to features_url
      end
    end
  end
end
