class CreateHubs < ActiveRecord::Migration[4.2]
  def change
    create_table :hubs do |t|
      t.string :title, :limit => 500.bytes, :null => false
      t.string :description, :limit => 2.kilobytes
      t.string :tag_prefix, :limit => 25.bytes

      t.timestamps
    end
    add_index :hubs, :title
    add_index :hubs, :tag_prefix
  end
end
