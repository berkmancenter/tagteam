class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :title
      t.string :description
      t.string :flavor
      t.string :url
      t.string :feed_url
      t.string :etag

      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
