class FixDataPublishedInFeedItems < ActiveRecord::Migration[5.0]
  def up
    FeedItem.where('date_published is null')
            .update_all('date_published = created_at')
  end

  def down; end
end
