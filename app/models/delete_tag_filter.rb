# An DeleteTagFilter lets you remove a ActsAsTaggableOn::Tag from an object via a HubTagFilter, HubFeedTagFilter or HubFeedItemTagFilter.
#
# Most validations are contained in the ModelExtensions mixin.
#
class DeleteTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  has_one :hub_tag_filter, :as => :filter
  has_one :hub_feed_tag_filter, :as => :filter
  has_one :hub_feed_item_tag_filter, :as => :filter

  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
  attr_accessible :tag_id
  validates_presence_of :tag_id

  api_accessible :default do|t|
    t.add :id
    t.add :tag
  end

  def css_class
    'delete'
  end

  def description
    'Delete tag: '
  end

  # Does the actual "filtering" by removing a tag from the tag list.
  def act(filtered_tags)
    filtered_tags.delete(self.tag.name)
  end

end
