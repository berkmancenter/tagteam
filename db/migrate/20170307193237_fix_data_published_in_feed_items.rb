class FixDataPublishedInFeedItems < ActiveRecord::Migration[5.0]
  def change
    FeedItem.all.each do |feed_item|
      unless feed_item.date_published
        feed_item.date_published = feed_item.created_at
        feed_item.save
      end
    end
  end
end
