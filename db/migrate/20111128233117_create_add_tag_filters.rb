class CreateAddTagFilters < ActiveRecord::Migration
  def change
    create_table :add_tag_filters do |t|
      t.references :tag
      t.timestamps
    end
    add_index :add_tag_filters, :tag_id
  end
end
