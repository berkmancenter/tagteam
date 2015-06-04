class AddActiveToTagging < ActiveRecord::Migration
  def change
    add_column :taggings, :active, :boolean, default: true
    add_index :taggings, :active
  end
end
