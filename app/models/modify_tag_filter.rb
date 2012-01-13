class ModifyTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  has_many :hub_tag_filters, :as => :filter
  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, :class_name => 'ActsAsTaggableOn::Tag'
  validates_presence_of :tag_id, :new_tag_id

  def css_class
    'modify'
  end

  def act(filtered_tags)
    filtered_tags.delete(self.tag.name)
    filtered_tags << self.new_tag.name
  end

end
