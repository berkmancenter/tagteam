class CreateHubFeeds < ActiveRecord::Migration
  def self.up
    create_table :hub_feeds do |t|
      t.references :feed
      t.references :hub
      t.string :title
      t.string :description

      t.timestamps
    end
    add_index :hub_feeds, :feed_id
    add_index :hub_feeds, :hub_id

  end

  def self.down
    drop_table :hub_feeds
  end
end
