class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_many :feed_items 
end
