class AddTagCountToHubs < ActiveRecord::Migration
  def change
    add_column :hubs, :tag_count, :text, :limit => 1.megabyte
  end
end
