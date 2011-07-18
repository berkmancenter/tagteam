class CreateHubs < ActiveRecord::Migration
  def self.up
    create_table :hubs do |t|
      t.string :title, :limit => 255, :null => false
      t.string :description
      t.string :tag_prefix, :limit => 25

      t.timestamps
    end
    add_index :hubs, :title
  end

  def self.down
    drop_table :hubs
  end
end
