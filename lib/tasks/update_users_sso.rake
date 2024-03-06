require 'rake'

namespace :gwss do
    # To be used for migrating user records for GW users that do not 
    desc "Updates user records for use with SSO" 

    task :update_users_sso => :environment do    
            # Regex to match GW email address patterns
        gw_email = /@((gwmail|email).)*gwu.edu/
        User.find_each do |user|
            if gw_email.match(user.email) 
                user.uid = user.email
                user.provider = "saml"
                user.save
            end
        end
    end 
end