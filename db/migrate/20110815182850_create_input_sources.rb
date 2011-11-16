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

    # Index for item_source_type is in the unique index below.
    #
    [:republished_feed_id, :item_source_id, :effect, :position].each do |col|
      add_index :input_sources, col
    end

    add_index :input_sources, [:item_source_type, :item_source_id, :effect, :republished_feed_id], :unique => true, :name => 'bob_the_index'

  end

  def self.down
    drop_table :input_sources
  end
end
