class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Curation Concerns behaviors.
  include CurationConcerns::User
  # Connects this user object to Sufia behaviors.
  include Sufia::User
  include Sufia::UserUsageStats




  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  if Rails.application.config.shibboleth == true
    devise :database_authenticatable, :trackable, :omniauthable, :omniauth_providers => [:shibboleth]
    
    def self.from_omniauth(auth)
      user = find_by(provider: auth.provider, uid: auth.uid) || new(uid: auth.uid, provider: auth.provider)
      user.update!(email: auth.info.email,
                   display_name: auth.info.first_name + auth.info.last_name,
                   affiliation: auth.extra.raw_info.affiliation,
	           shib_group: auth.extra.raw_info.isMemberOf,
		   :shib_last_update => DateTime.current,
		   :shibboleth_id => auth[:extra][:raw_info][:"Shib-Session-ID"])
      user
    end

  else
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  end

end
