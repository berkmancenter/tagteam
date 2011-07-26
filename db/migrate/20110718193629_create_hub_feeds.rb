class CreateHubFeeds < ActiveRecord::Migration
  def self.up
    create_table :hub_feeds do |t|
      t.references :feed
      t.string :title
      t.string :description

      t.timestamps
    end
    add_index :hub_feeds, :feed_id

    create_table :feeds_hub_feeds, :id => false, :force => true do|t|
      t.references :feed
      t.references :hub_feed
    end
    add_index :feeds_hub_feeds, :feed_id
    add_index :feeds_hub_feeds, :hub_feed_id

  end

  def self.down
    drop_table :hub_feeds
  end
end
