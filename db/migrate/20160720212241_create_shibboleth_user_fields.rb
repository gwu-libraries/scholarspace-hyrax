class CreateUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :uid, :string
    add_column :users, :shibboleth_id, :string
    add_column :users, :provider, :string
  end
end
