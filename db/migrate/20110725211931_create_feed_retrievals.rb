class CreateFeedRetrievals < ActiveRecord::Migration
  def change
    create_table :feed_retrievals do |t|
      t.integer :feed_id
      t.boolean :success
      t.string :info, :limit => 5.kilobytes
      t.string :status_code, :limit => 25.bytes
      t.string :changelog, :limit => 1.megabyte

      t.timestamps
    end
  end
end
