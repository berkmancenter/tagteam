class CreateFeedItemTags < ActiveRecord::Migration
  def self.up
    create_table :feed_item_tags do |t|
      t.string :tag,          :limit => 255.bytes,    :null => false
      t.string :description,  :limit => 5.kilobytes
      t.timestamps
    end

    add_index :feed_item_tags, :tag, :unique => true

    create_table :feed_item_tags_feed_items, :id => false, :force => true do |t|
      t.references :feed_item
      t.references :feed_item_tag
    end

    add_index :feed_item_tags_feed_items, :feed_item_id
    add_index :feed_item_tags_feed_items, :feed_item_tag_id
  end

  def self.down
    drop_table :feed_item_tags
    drop_table :feed_item_tags_feed_items
  end
end
