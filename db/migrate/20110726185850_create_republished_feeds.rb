class CreateRepublishedFeeds < ActiveRecord::Migration[4.2]
  def change
    create_table :republished_feeds do |t|
      t.integer :hub_id
      t.string :title,            :limit => 500.bytes,    :null => false
      t.string :description,      :limit => 5.kilobytes
      t.integer :limit,           :default => 50

      t.timestamps
    end

    [:hub_id, :title].each do|col|
      add_index :republished_feeds, col
    end

  end
end
