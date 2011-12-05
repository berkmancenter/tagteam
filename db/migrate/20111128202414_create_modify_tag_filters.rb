class CreateModifyTagFilters < ActiveRecord::Migration
  def change
    create_table :modify_tag_filters do |t|
      t.references :tag
      t.references :new_tag
      t.timestamps
    end
    [:tag_id, :new_tag_id].each do|col|
      add_index :modify_tag_filters, col
    end
  end
end
