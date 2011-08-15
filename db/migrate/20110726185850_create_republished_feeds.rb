class CreateRepublishedFeeds < ActiveRecord::Migration

  def self.up
    create_table :republished_feeds do |t|
      t.integer :hub_id
      t.string :title,            :limit => 500.bytes,    :null => false
      t.string :description,      :limit => 5.kilobytes
      t.string :default_sort,     :limit => 100.bytes,          :default => 'date_published'
      t.string :mixing_strategy,  :limit => 25.bytes,           :default => 'interlaced'
      t.integer :limit,           :default => 50

      t.timestamps
    end

    [:hub_id, :title].each do|col|
      add_index :republished_feeds, col
    end

  end

  def self.down
    drop_table :republished_feeds
  end
end
