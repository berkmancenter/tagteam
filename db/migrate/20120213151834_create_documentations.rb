class CreateDocumentations < ActiveRecord::Migration
  def change
    create_table :documentations do |t|
      t.string :match_key, :limit => 100.bytes, :null => false
      t.string :title, :limit => 500.bytes, :null => false
      t.string :description, :limit => 1.megabyte
      t.string :lang, :limit => 2.bytes, :default => 'en'
      t.timestamps
    end
    add_index :documentations, :match_key, :unique => true
    add_index :documentations, :lang
    add_index :documentations, :title
  end
end
