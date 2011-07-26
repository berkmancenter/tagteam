class CreateHubTagFilters < ActiveRecord::Migration
  def self.up
    create_table :hub_tag_filters do |t|
      t.integer :hub_id
      t.integer :tag_filter_id
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :hub_tag_filters
  end
end
