module Hyrax
    module DashboardControllerDecorator

        # If the user does not have one of the admin roles, we don't want them to have access to the dashboard, so we direct to the home page 
        def redirect_non_admin_user
            if !current_user.admin? && !current_user.contentadmin?
                redirect_to root_path
            end
        end
    end
end

Hyrax::DashboardController.prepend Hyrax::DashboardControllerDecorator

