class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_many :feed_items 

  after_save :update_feed_updated_at

  def update_feed_updated_at
    self.feed.updated_at = DateTime.now
    self.feed.save
  end

end
