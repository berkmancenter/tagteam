class CreateFeedItems < ActiveRecord::Migration
  def self.up
    create_table :feed_items do |t|
      t.integer :feed_id
      t.integer :feed_retrieval_id
      t.string :title,              :limit => 500.bytes
      t.string :url,                :limit => 2.kilobytes
      # Not going to work in mysql.
      t.string :author,             :limit => 1.kilobyte
      t.string :description,        :limit => 5.kilobytes
      t.string :content,            :limit => 1.megabyte
      t.string :copyright,          :limit => 500.bytes
      t.datetime :date_published

      t.timestamps
    end

    [:feed_id, :feed_retrieval_id, :date_published].each do|col|
      add_index :feed_items, col
    end

    add_index :feed_items, :url, :unique => true

    create_table :feed_items_feeds, :id => false, :force => true do |t|
      t.references :feed
      t.references :feed_item
    end

    add_index :feed_items_feeds, :feed_id
    add_index :feed_items_feeds, :feed_item_id

  end

  def self.down
    drop_table :feed_items
    drop_table :feed_items_feeds
  end
end
