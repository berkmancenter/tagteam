# Changes an ActsAsTaggableOn::Tag into another ActsAsTaggableOn::Tag, effectively renaming a tag.
# 
# Most validations are contained in the ModelExtensions mixin.
#
class ModifyTagFilter < ActiveRecord::Base
  include ModelExtensions
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  has_one :hub_tag_filter, :as => :filter
  has_one :hub_feed_tag_filter, :as => :filter
  has_one :hub_feed_item_tag_filter, :as => :filter

  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, :class_name => 'ActsAsTaggableOn::Tag'
  validates_presence_of :tag_id, :new_tag_id
  attr_accessible :tag_id, :new_tag_id

  api_accessible :default do|t|
    t.add :id
    t.add :tag
    t.add :new_tag
  end

  validate :tag_id do
    if self.tag_id == self.new_tag_id
      self.errors.add(:new_tag_id, " can't be the same as the original tag")
    end
  end

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

  def self.title
    'Modify tag filter'
  end

end
