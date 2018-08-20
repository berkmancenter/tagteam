class CreateHubFeedTagFilters < ActiveRecord::Migration[4.2]
  def change
    create_table :hub_feed_tag_filters do |t|
      t.references :hub_feed
      t.string :filter_type, :limit => 100, :null => false
      t.integer :filter_id, :null => false

      t.timestamps
    end
    [:hub_feed_id, :filter_type, :filter_id].each do|col|
      add_index :hub_feed_tag_filters, col
    end
  end
end
