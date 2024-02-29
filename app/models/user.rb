class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles


  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats



  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:saml]

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def contentadmin?
    roles.where(name: 'content-admin').exists?
  end

  def self.from_omniauth(access_token)
    Rails.logger.debug "access_token = #{access_token.extra.response_object.attributes['urn:oid:0.9.2342.19200300.100.1.3'].inspect}"
    email = case access_token.provider.to_s
            when 'saml' then "#{access_token.uid}@gwu.edu"
            else access_token.uid
    end

    User.where(email: email).first_or_create do |user|
        user.email = email
        user.display_name = access_token.extra.response_object.attributes['urn:oid:2.16.840.1.113730.3.1.241']
        user.password = SecureRandom.urlsafe_base64
    end
  end
  
end

