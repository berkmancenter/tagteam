class CreateFeedItems < ActiveRecord::Migration
  def self.up
    create_table :feed_items do |t|
      t.integer :feed_id
      t.integer :feed_retrieval_id
      t.string :title,              :limit => 500.bytes
      t.string :url,                :limit => 2.kilobytes
      # Not going to work in mysql.
      t.string :author,             :limit => 1.kilobyte
      t.string :description,        :limit => 5.kilobytes
      t.string :content,            :limit => 1.megabyte
      t.string :copyright,          :limit => 500.bytes
      t.datetime :date_published

      t.timestamps
    end

    [:feed_id, :feed_retrieval_id, :date_published, :url].each do|col|
      add_index :feed_items, col
    end

    add_index :feed_items, [:url,:feed_id], :unique => true

  end

  def self.down
    drop_table :feed_items
  end
end
