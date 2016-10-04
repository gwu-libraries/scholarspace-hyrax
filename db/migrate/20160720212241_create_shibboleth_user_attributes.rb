class CreateShibbolethUserAttributes < ActiveRecord::Migration
  def self.up
    add_column :users, :uid, :string
    add_column :users, :shibboleth_id, :string
    add_column :users, :provider, :string
    add_column :users, :shib_group, :string
  end
end
