class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :title,        :limit => 500.bytes
      t.string :description,  :limit => 2.kilobytes
      t.string :guid,         :limit => 1.kilobyte
      t.datetime :last_updated
      t.string :rights,       :limit => 500.bytes
      t.string :authors,      :limit => 1.kilobyte
      t.string :feed_url,     :null => false,       :limit => 1.kilobyte
      t.string :link,         :limit => 1.kilobyte
      t.string :generator,    :limit => 500.bytes
      t.string :flavor,       :limit => 25.bytes
      t.string :language,     :limit => 25.bytes
      t.datetime :next_scheduled_retrieval

      t.timestamps
    end
    [:guid,:authors,:generator,:flavor, :next_scheduled_retrieval].each do|col|
      add_index :feeds, col
    end
    add_index :feeds, :feed_url, :unique => true
  end

  def self.down
    drop_table :feeds
  end
end
