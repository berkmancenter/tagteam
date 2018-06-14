class CreateFeeds < ActiveRecord::Migration[4.2]
  def change
    create_table :feeds do |t|
      t.string :title,        :limit => 500.bytes
      t.string :description,  :limit => 2.kilobytes
      t.string :guid,         :limit => 1.kilobyte
      t.datetime :last_updated
      t.datetime :items_changed_at
      t.string :rights,       :limit => 500.bytes
      t.string :authors,      :limit => 1.kilobyte
      t.string :feed_url,     :null => false,       :limit => 1.kilobyte
      t.string :link,         :limit => 1.kilobyte
      t.string :generator,    :limit => 500.bytes
      t.string :flavor,       :limit => 25.bytes
      t.string :language,     :limit => 25.bytes
      t.boolean :bookmarking_feed, :default => false
      t.datetime :next_scheduled_retrieval

      t.timestamps
    end
    [:guid, :authors, :generator, :flavor, :next_scheduled_retrieval, :bookmarking_feed, :feed_url].each do|col|
      add_index :feeds, col
    end
  end
end
