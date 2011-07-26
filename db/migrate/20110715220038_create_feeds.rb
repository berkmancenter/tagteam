class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :title,        :null => false,       :limit => 500.bytes
      t.string :description,  :limit => 2.kilobytes
      t.string :guid,         :limit => 500.bytes
      t.datetime :last_updated
      t.string :copyright,    :limit => 500.bytes
      t.string :authors,      :limit => 1.kilobyte
      t.string :feed_url,     :null => false,       :limit => 500.bytes
      t.string :generator,    :limit => 500.bytes
      t.string :flavor,       :limit => 25.bytes

      t.timestamps
    end
    [:guid,:authors,:generator,:flavor].each do|col|
      add_index :feeds, col
    end
    add_index :feeds, :feed_url, :unique => true
  end

  def self.down
    drop_table :feeds
  end
end
