class FeedItemTag < ActiveRecord::Base
  include ModelExtensions
  belongs_to :hub
  validates_inclusion_of :hub_id

  has_and_belongs_to_many :feed_items
  validates_uniqueness_of :tag

end
