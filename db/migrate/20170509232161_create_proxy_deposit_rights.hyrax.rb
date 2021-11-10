# This migration comes from hyrax (originally 20160328222226)
class CreateProxyDepositRights < ActiveRecord::Migration[5.0]
  def change
    create_table :proxy_deposit_rights do |t|
      t.references :grantor
      t.references :grantee
      t.timestamps null: false
    end
  end
end
