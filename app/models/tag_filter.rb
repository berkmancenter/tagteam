class TagFilter < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions

  belongs_to :hub
  belongs_to :scope, polymorphic: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag'
  has_many :taggings, as: :tagger, class_name: 'ActsAsTaggableOn::Tagging'
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

  scope :applied, where(applied: true)

  def items_in_scope
    scope.taggable_items
  end

  def most_recent?
    hub.all_tag_filters.applied.order('updated_at DESC').first == self
  end

  # Filter application can occur on a subset of items in a scope (if a new
  # items comes in from a feed, for example), but filter rollback always
  # happens for all items at once, so we don't need an items argument here.
  def rollback
    unless most_recent?
      raise 'Can only rollback the most recently applied filter - this is not that'
    end
    hub.before_tag_filter_destroy(self)
    reactivate_taggings!
    taggings.destroy_all
    self.update_attribute(:applied, false)
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
    # Deactivates any taggings that are the same except in owner, and do not
    # deactivate own taggings.
    return ActsAsTaggableOn::Tagging.where('1=2') if items.empty?
    ActsAsTaggableOn::Tagging.
      where(context: hub.tagging_key, tag_id: tag.id,
            taggable_type: FeedItem, taggable_id: items.pluck(:id)).
      where('("taggings"."tagger_id" IS NULL AND ' +
            '"taggings"."tagger_type" IS NULL) OR ' +
            '(NOT ("taggings"."tagger_id" = ? AND "taggings"."tagger_type" = ?))',
            self.id, self.class.base_class.name)
  end

  def reactivates_taggings
    DeactivatedTagging.
      where(context: hub.tagging_key, tag_id: tag.id,
            taggable_type: FeedItem, taggable_id: items_in_scope.pluck(:id))
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

  def self.in_hub(hub)
    where(hub_id: hub.id)
  end

  # This is useful when we're using sidekiq.
  def self.apply_by_id(id)
    self.find(id).apply
  end
end
