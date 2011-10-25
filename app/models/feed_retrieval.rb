class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_and_belongs_to_many :feed_items 

  scope :successful, where(['success is true'])

  after_save :update_feed_updated_at

  def update_feed_updated_at
    self.feed.updated_at = DateTime.now
    self.feed.save
  end

end
