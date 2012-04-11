class CreateHubTagFilters < ActiveRecord::Migration
  def change
    create_table :hub_tag_filters do |t|
      t.references :hub
      t.string :filter_type, :limit => 100, :null => false
      t.integer :filter_id, :null => false

      t.timestamps
    end
    [:hub_id, :filter_type, :filter_id].each do|col|
      add_index :hub_tag_filters, col
    end
  end

end
