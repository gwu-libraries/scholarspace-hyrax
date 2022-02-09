# This migration comes from hyrax (originally 20160401142419)
class CreateUploadedFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :uploaded_files do |t|
      t.string :file
      t.references :user, index: true, foreign_key: true
      t.string :file_set_uri, index: true
      t.timestamps null: false
    end
  end
end
