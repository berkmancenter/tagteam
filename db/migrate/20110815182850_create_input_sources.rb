class CreateInputSources < ActiveRecord::Migration
  def self.up
    create_table :input_sources do |t|
      t.integer :republished_feed_id,     :null => false
      t.integer :item_source_id,          :null => false
      t.string :item_source_type,         :limit => 100.bytes,    :null => false
      t.string :effect,                   :limit => 25.bytes,     :null => false,   :default => 'add'
      t.integer :position
      t.integer :limit

      t.timestamps
    end

    [:republished_feed_id, :item_source_id, :item_source_type, :effect, :position].each do |col|
      add_index :input_sources, col
    end

  end

  def self.down
    drop_table :input_sources
  end
end
