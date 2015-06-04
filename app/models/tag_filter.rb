class TagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :scope, polymorphic: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag'

  include ModelExtensions
  validates_presence_of :tag_id
  validates :scope_type, inclusion: { in: ['Hub', 'HubFeed', 'FeedItem'] }

  attr_accessible :tag_id

  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :tag
  end

  def owner
  end

  def creator
  end

  def items_in_scope
    scope.taggable_items
  end

  def description
    self.class.name.sub('TagFilter', '')
  end

  def css_class
    # Not using description because they css_class and desc differ sometimes
    self.class.name.sub('TagFilter', '').downcase
  end

  def deactivate_taggings!
    deactivates_taggings.update_all(active: false)
  end

  def reactivate_taggings!
    reactivates_taggings.update_all(active: true)
  end

  def taggings
    # We don't care if they're active or not
    ActsAsTaggableOn::Tagging.unscoped.where(tagger: self)
  end

  def self.title
    "#{self.name.sub('TagFilter', '')} tag filter"
  end
end
