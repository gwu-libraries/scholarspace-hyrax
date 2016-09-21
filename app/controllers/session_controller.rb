class SessionsController < ApplicationController
  def destroy
    sign_out :user
    redirect_to Sufia::Engine.config.logout_url
  end

  def new
    redirect_to Sufia::Engine.config.login_url
  end
end
