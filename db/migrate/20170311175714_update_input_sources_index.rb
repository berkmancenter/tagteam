class UpdateInputSourcesIndex < ActiveRecord::Migration[5.0]
  def up
    remove_index :input_sources, [:item_source_type, :item_source_id, :effect, :republished_feed_id]

    add_index :input_sources, [:item_source_type, :item_source_id, :effect, :republished_feed_id, :created_by_only_id], :unique => true, :name => 'bob_the_index'
  end

  def down
    remove_index :input_sources, [:item_source_type, :item_source_id, :effect, :republished_feed_id, :created_by_only_id]

    add_index :input_sources, [:item_source_type, :item_source_id, :effect, :republished_feed_id], :unique => true, :name => 'bob_the_index'
  end
end
