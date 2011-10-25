class CreateFeedRetrievals < ActiveRecord::Migration
  def self.up
    create_table :feed_retrievals do |t|
      t.integer :feed_id
      t.boolean :success
      t.string :info, :limit => 5.kilobytes
      t.string :status_code, :limit => 25.bytes

      t.timestamps
    end
  end

  def self.down
    drop_table :feed_retrievals
  end
end
