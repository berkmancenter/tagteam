class CreateHubFeedItemTagFilters < ActiveRecord::Migration
  def change
    create_table :hub_feed_item_tag_filters do |t|
      t.integer :hub_id
      t.integer :feed_item
      t.string :filter_type
      t.integer :filter_id
      t.integer :position

      t.timestamps
    end
  end
end
