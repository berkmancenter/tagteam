class AddImageUrlToFeedItem < ActiveRecord::Migration
  def change
    add_column :feed_items, :image_url, :text
  end
end
