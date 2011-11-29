class CreateAddTagFilters < ActiveRecord::Migration
  def change
    create_table :add_tag_filters do |t|
      t.integer :feed_item_tag_id
      t.timestamps
    end
    add_index :add_tag_filters, :feed_item_tag_id
  end
end
