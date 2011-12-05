class CreateDeleteTagFilters < ActiveRecord::Migration
  def change
    create_table :delete_tag_filters do |t|
      t.references :tag
      t.timestamps
    end
    add_index :delete_tag_filters, :tag_id
  end
end
