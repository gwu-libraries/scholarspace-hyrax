class Ability
  include Hydra::Ability
  
  include Hyrax::Ability
  self.ability_logic += [:contentadmins_can_create_curation_concerns]

  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end

    if current_user.admin?
      can [:create, :show, :add_user, :remove_user, :index, :edit, :update, :destroy], Role
    end

#    if current_user.contentadmin?
#      can [:create, :destroy], GwWork
#      can [:create, :destroy], GwEtd
#    end
  end

  def contentadmin_user?
    current_user.contentadmin?
  end

  def contentadmins_can_create_curation_concerns
    return unless contentadmin_user?
    can [:index, :show, :edit, :create], curation_concerns_models
    # user can version if they can edit
    alias_action :versions, to: :update
    alias_action :file_manager, to: :update

    can :index, Hydra::AccessControls::Embargo
    can :index, Hydra::AccessControls::Lease
  end
end
