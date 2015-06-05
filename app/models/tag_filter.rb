class TagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :scope, polymorphic: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag'
  has_many :taggings, as: :tagger
  has_many :deactivated_taggings, as: :tagger

  VALID_SCOPE_TYPES = ['Hub', 'HubFeed', 'FeedItem']
  include ModelExtensions
  validates_presence_of :tag_id
  validates :scope_type, inclusion: { in: VALID_SCOPE_TYPES }

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

  def rollback
    # We rollback any filters ahead of this filter in the chain, so we can
    # always assume that this is the most recent filter.
    reactivate_taggings!
    taggings.destroy_all
  end

  # Somewhat surprisingly, this code is the same for the add and delete
  # filters. In the add filter, it deactivates what would be duplicate
  # taggings. In the delete filter, it deactivates the taggings it's supposed
  # to.
  #
  # For example, if hub filter adds 'tag1', and now we create a feed filter
  # that adds 'tag1', all the 'tag1' tags for items in this feed should be
  # owned by the feed filter.
  def deactivates_taggings
    # Deactivates any taggings that are the same except in owner.
    ActsAsTaggableOn::Tagging.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items_in_scope.pluck(:id))
  end

  def reactivates_taggings
    DeactivatedTagging.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items_in_scope.pluck(:id))
  end

  def deactivate_taggings!
    deactivates_taggings.each(&:deactivate)
  end

  def reactivate_taggings!
    reactivates_taggings.each(&:reactivate)
  end

  def self.title
    "#{self.name.sub('TagFilter', '')} tag filter"
  end
end
