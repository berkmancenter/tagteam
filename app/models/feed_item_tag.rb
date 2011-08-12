class FeedItemTag < ActiveRecord::Base
  include ModelExtensions
  has_and_belongs_to_many :feed_items
end
