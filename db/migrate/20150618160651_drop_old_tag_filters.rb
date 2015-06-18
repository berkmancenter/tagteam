class DropOldTagFilters < ActiveRecord::Migration
  def up
    drop_table :hub_tag_filters
    drop_table :hub_feed_tag_filters
    drop_table :hub_feed_item_tag_filters
    drop_table :add_tag_filters
    drop_table :modify_tag_filters
    drop_table :delete_tag_filters
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
