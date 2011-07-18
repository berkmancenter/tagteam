class CreateHubFeeds < ActiveRecord::Migration
  def self.up
    create_table :hub_feeds do |t|
      t.integer :feed_id
      t.string :title
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :hub_feeds
  end
end
