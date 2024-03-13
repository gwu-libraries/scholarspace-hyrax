# frozen_string_literal: true
#require 'pry-remote'
class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  def destroy
    # Preserve the saml_uid and saml_session_index in the session
    saml_uid = session['saml_uid']
    saml_session_index = session['saml_session_index']
    super do
      session['saml_uid'] = saml_uid
      session['saml_session_index'] = saml_session_index
    end
  end

  def after_sign_out_path_for(_)
    if session['saml_uid'] && session['saml_session_index'] #&& SAML_SETTINGS.idp_slo_service_url
      #binding.remote_pry
      user_saml_omniauth_authorize_path + "/spslo"
    else
      super
    end
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
