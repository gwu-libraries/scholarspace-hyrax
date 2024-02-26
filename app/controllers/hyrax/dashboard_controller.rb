# frozen_string_literal: true
#require 'pry-remote'
module Hyrax
  class DashboardController < ApplicationController
    include Blacklight::Base
    include Hyrax::Breadcrumbs
    with_themed_layout 'dashboard'
    before_action :authenticate_user!
    before_action :redirect_non_admin_user
    before_action :build_breadcrumbs, only: [:show]
    before_action :set_date_range

    ##
    # @!attribute [rw] sidebar_partials
    #   @return [Hash]
    #
    # @example Add a custom partial to the tasks sidebar block
    #   Hyrax::DashboardController.sidebar_partials[:tasks] << "hyrax/dashboard/sidebar/custom_task"
    class_attribute :sidebar_partials
    self.sidebar_partials = { activity: [], configuration: [], repository_content: [], tasks: [] }

    def show
      #binding.remote_pry
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::DashboardPresenter.new
        @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
        render 'show_admin'
      else
        @presenter = Dashboard::UserPresenter.new(current_user, view_context, params[:since])
        render 'show_user'
      end
    end

    private

    def set_date_range
      @start_date = params[:start_date] || Time.zone.today - 1.month
      @end_date = params[:end_date] || Time.zone.today + 1.day
    end
    
    # If the user does not have one of the admin roles, we don't want them to have access to the dashboard
    # so we direct to the home page 
    def redirect_non_admin_user
        if current_user.roles.none? { |role| role.name == 'content-admin' || role.name == 'admin'  } 
            redirect_to root_path
        end
    end
  end
end
