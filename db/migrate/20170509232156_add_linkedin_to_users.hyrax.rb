# This migration comes from hyrax (originally 20160328222162)
class AddLinkedinToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :linkedin_handle, :string
  end
end
