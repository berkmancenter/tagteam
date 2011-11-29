class CreateDeleteTagFilters < ActiveRecord::Migration
  def change
    create_table :delete_tag_filters do |t|
      t.references :feed_item_tag
      t.timestamps
    end
    add_index :delete_tag_filters, :feed_item_tag_id
  end
end
