class ModifyTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  has_one :hub_tag_filter, :as => :filter
  has_one :hub_feed_tag_filter, :as => :filter
  has_one :hub_feed_item_tag_filter, :as => :filter

  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, :class_name => 'ActsAsTaggableOn::Tag'
  validates_presence_of :tag_id, :new_tag_id

  def description
    'Change tag '
  end

  def css_class
    'modify'
  end

  def act(filtered_tags)
    if filtered_tags.include?(self.tag.name)
      filtered_tags.delete(self.tag.name)
      filtered_tags << self.new_tag.name
    end
    filtered_tags
  end

end
