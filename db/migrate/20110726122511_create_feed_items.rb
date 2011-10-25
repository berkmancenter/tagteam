class CreateFeedItems < ActiveRecord::Migration
  def self.up
    create_table :feed_items do |t|
      t.string :title,              :limit => 500.bytes
      t.string :url,                :limit => 2.kilobytes
      t.string :guid,               :limit => 1.kilobyte
      t.string :authors,             :limit => 1.kilobyte
      t.string :contributors,        :limit => 1.kilobyte

      t.string :description,        :limit => 5.kilobytes
      # Not going to work in mysql.
      t.string :content,            :limit => 1.megabyte
      t.string :rights,             :limit => 500.bytes
      t.datetime :date_published
      t.datetime :last_updated

      t.timestamps
    end

    [:date_published, :authors, :contributors].each do|col|
      add_index :feed_items, col
    end

    add_index :feed_items, :url, :unique => true

    create_table :feed_items_feeds, :id => false, :force => true do |t|
      t.references :feed
      t.references :feed_item
    end

    add_index :feed_items_feeds, :feed_id
    add_index :feed_items_feeds, :feed_item_id

    create_table :feed_items_feed_retrievals, :id => false, :force => true do |t|
      t.references :feed_item
      t.references :feed_retrieval
    end

    add_index :feed_items_feed_retrievals, :feed_item_id
    add_index :feed_items_feed_retrievals, :feed_retrieval_id

  end

  def self.down
    drop_table :feed_items
    drop_table :feed_items_feeds
    drop_table :feed_items_feed_retrievals
  end
end
