class CreateModifyTagFilters < ActiveRecord::Migration
  def change
    create_table :modify_tag_filters do |t|
      t.integer :feed_item_tag_id
      t.integer :new_feed_item_tag_id
      t.timestamps
    end
    [:feed_item_tag_id, :new_feed_item_tag_id].each do|col|
      add_index :modify_tag_filters, col
    end
  end
end
