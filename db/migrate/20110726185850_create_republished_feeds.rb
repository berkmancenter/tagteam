class CreateRepublishedFeeds < ActiveRecord::Migration
  def self.up
    create_table :republished_feeds do |t|
      t.integer :hub_id
      t.string :title
      t.string :description
      t.string :feed_input_type
      t.integer :feed_input_id
      t.string :default_sort
      t.string :mixing_strategy
      t.integer :item_limit

      t.timestamps
    end
  end

  def self.down
    drop_table :republished_feeds
  end
end
