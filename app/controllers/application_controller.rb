class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  skip_after_action :discard_flash_if_xhr
  include Hydra::Controller::ControllerBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  protect_from_forgery with: :exception

  # Disable the I18n parameter if we are in the logout phase
  # This prevents the locale= parameter from appearing in the auth/saml route
  # May be due to an omniauth-saml bug?
  def default_url_options
    if params[:controller] && params[:controller].include?("users/sessions")
      super.merge(locale: nil)
    else
      super
    end
  end
end