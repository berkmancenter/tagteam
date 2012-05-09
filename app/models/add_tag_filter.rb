# An AddTagFilter lets you add a ActsAsTaggableOn::Tag to an object via a HubTagFilter, HubFeedTagFilter or HubFeedItemTagFilter.
# 
# Most validations are contained in the ModelExtensions mixin.
#
class AddTagFilter < ActiveRecord::Base
  include ModelExtensions
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  has_one :hub_tag_filter, :as => :filter
  has_one :hub_feed_tag_filter, :as => :filter
  has_one :hub_feed_item_tag_filter, :as => :filter

  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
  validates_presence_of :tag_id
  attr_accessible :tag_id

  api_accessible :default do|t|
    t.add :id
    t.add :tag
  end

  def description
    'Add tag: '
  end

  def css_class
    'add'
  end

  # Does the actual "filtering" by appending itself into the tag list.
  def act(filtered_tags)
    filtered_tags << self.tag.name
  end

end
