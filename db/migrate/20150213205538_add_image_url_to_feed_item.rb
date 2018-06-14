class AddImageUrlToFeedItem < ActiveRecord::Migration[4.2]
  def change
    add_column :feed_items, :image_url, :text
  end
end
