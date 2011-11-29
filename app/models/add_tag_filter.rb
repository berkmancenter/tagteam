class AddTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  has_many :hub_tag_filters, :as => :filter
  belongs_to :feed_item_tag
  validates_presence_of :feed_item_tag_id
end
