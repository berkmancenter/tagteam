class DeleteTagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  acts_as_authorization_object

  has_many :hub_tag_filters, :as => :filter
  belongs_to :tag, :class_name => 'ActsAsTaggableOn::Tag'
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
