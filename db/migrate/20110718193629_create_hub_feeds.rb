class CreateHubFeeds < ActiveRecord::Migration
  def self.up
    create_table :hub_feeds do |t|
      t.integer :feed_id, :null => false
      t.integer :hub_id, :null => false
      t.string :title, :limit => 500.bytes 
      t.string :description, :limit => 2.kilobytes

      t.timestamps
    end
    add_index :hub_feeds, :feed_id
    add_index :hub_feeds, :hub_id
    add_index :hub_feeds, [:hub_id, :feed_id], :unique => true

  end

  def self.down
    drop_table :hub_feeds
  end
end
