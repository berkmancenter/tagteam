class CreateFeedItems < ActiveRecord::Migration
  def self.up
    create_table :feed_items do |t|
      t.integer :feed_id
      t.integer :feed_retrieval_id
      t.string :title
      t.string :url
      t.string :author
      t.string :description
      t.string :content
      t.string :copyright
      t.datetime :date_published

      t.timestamps
    end
  end

  def self.down
    drop_table :feed_items
  end
end
