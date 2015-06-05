class TagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions

  belongs_to :hub
  belongs_to :scope, polymorphic: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag'
  has_many :taggings, as: :tagger
  has_many :deactivated_taggings, as: :tagger

  before_destroy :rollback

  VALID_SCOPE_TYPES = ['Hub', 'HubFeed', 'FeedItem']
  validates_presence_of :tag_id
  validates_inclusion_of :scope_type, in: VALID_SCOPE_TYPES
  validates_uniqueness_of :tag_id, scope: [:scope_type, :scope_id],
    message: 'Filter conflicts with existing filter.'

  attr_accessible :tag_id

  acts_as_authorization_object
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :tag
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

  # Filter application can occur on a subset of items in a scope (if a new
  # items comes in from a feed, for example), but filter rollback always
  # happens for all items at once, so we don't need an items argument here.
  def rollback
    hub.before_tag_filter_destroy(self)
    reactivate_taggings!
    taggings.destroy_all
    hub.after_tag_filter_destroy(self)
  end

  # Somewhat surprisingly, this code is the same for the add and delete
  # filters. In the add filter, it deactivates what would be duplicate
  # taggings. In the delete filter, it deactivates the taggings it's supposed
  # to.
  #
  # For example, if hub filter adds 'tag1', and now we create a feed filter
  # that adds 'tag1', all the 'tag1' tags for items in this feed should be
  # owned by the feed filter.
  def deactivates_taggings(items: items_in_scope)
    # Deactivates any taggings that are the same except in owner.
    ActsAsTaggableOn::Tagging.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items.pluck(:id))
  end

  def reactivates_taggings
    DeactivatedTagging.
      where(context: hub.tagging_key, tag_id: tag.id, taggable_type: FeedItem).
      where('taggable_id IN ?', items_in_scope.pluck(:id))
  end

  def deactivate_taggings!(items: items_in_scope)
    deactivates_taggings(items: items).each(&:deactivate)
  end

  def reactivate_taggings!
    reactivates_taggings.each(&:reactivate)
  end

  def self.title
    "#{self.name.sub('TagFilter', '')} tag filter"
  end
end
