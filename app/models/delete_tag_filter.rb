class DeleteTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  has_one :hub_tag_filter, :as => :filter
  has_one :hub_feed_tag_filter, :as => :filter
  has_one :hub_feed_item_tag_filter, :as => :filter

  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
  attr_accessible :tag_id
  validates_presence_of :tag_id

  def css_class
    'delete'
  end

  def description
    'Delete tag: '
  end

  def act(filtered_tags)
    filtered_tags.delete(self.tag.name)
  end

end
