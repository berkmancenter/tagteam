class ModifyTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  has_many :hub_tag_filters, :as => :filter
  belongs_to :feed_item_tag
  belongs_to :new_feed_item_tag, :class_name => FeedItemTag
  validates_presence_of :feed_item_tag_id, :new_feed_item_tag_id

  def css_class
    'modify'
  end

  def act(filtered_tags)
    filtered_tags.delete(self.feed_item_tag)
    filtered_tags << self.new_feed_item_tag
  end

end
