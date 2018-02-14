# frozen_string_literal: true

class TagFilter < ApplicationRecord
  include AuthUtilities
  include ModelExtensions
  include TaggingDeactivator

  belongs_to :hub
  belongs_to :scope, polymorphic: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag'
  has_many :taggings, as: :tagger, class_name: 'ActsAsTaggableOn::Tagging'
  has_many :deactivated_taggings, as: :tagger

  VALID_SCOPE_TYPES = %w[Hub HubFeed FeedItem].freeze
  validates :tag_id, presence: true
  validates :scope_type, inclusion: { in: VALID_SCOPE_TYPES }
  validates :tag_id, uniqueness: { scope: %i[scope_type scope_id],
                                   message: 'Filter conflicts with existing filter.' }

  attr_accessible :tag_id, :hub_id, :new_tag_id, :type, :scope_type, :scope_id,
                  :applied

  acts_as_authorization_object
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :tag
  end

  scope :applied, -> { where(applied: true) }

  delegate :name, to: :tag, prefix: true
  delegate :name, to: :new_tag, prefix: true

  def items_in_scope
    scope.taggable_items
  end

  def filter_to_scope(items)
    items.where(id: items_in_scope.pluck(:id))
  end

  def next_to_apply?
    applied == false &&
      (hub.tag_filters_before(self).count ==
        hub.tag_filters_before(self).applied.count) &&
      (hub.tag_filters_after(self).applied.count == 0)
  end

  def apply_async(reapply = false)
    ApplyTagFilters.perform_async(id, [], reapply)
  end

  # Filter application can occur on a subset of items in a scope (if a new
  # items comes in from a feed, for example), but filter rollback always
  # happens for all items at once, so we don't need an items argument here.
  def rollback
    TagFilter.transaction do
      taggings.destroy_all
      reactivate_taggings!
      update_column(:applied, false)
    end
    self.class.base_class.notify_observers :after_rollback, self
  end

  def rollback_and_destroy_async(current_user)
    TagFilters::DestroyJob.perform_later(self, current_user)
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
    ActsAsTaggableOn::Tagging
      .where(context: hub.tagging_key, tag_id: tag.id,
             taggable_type: 'FeedItem', taggable_id: items.pluck(:id))
      .where('("taggings"."tagger_id" IS NULL AND ' \
            '"taggings"."tagger_type" IS NULL) OR ' \
            '(NOT ("taggings"."tagger_id" = ? AND "taggings"."tagger_type" = ?))',
             id, self.class.base_class.name)
  end

  def deactivate_taggings!(items: items_in_scope)
    deactivates_taggings(items: items).find_each do |tagging|
      deactivate_tagging(tagging)
    end
  end

  def filter_chain
    filters_before + [self] + filters_after
  end

  def self.title
    "#{name.sub('TagFilter', '')} tag filter"
  end

  def self.in_hub(hub)
    where(hub_id: hub.id)
  end

  # This is useful when we're using sidekiq.
  def self.apply_by_id(id)
    find(id).apply
  end

  def self.rollback_by_id(id)
    find(id).rollback
  end

  def items_to_modify
    items_to_process = []

    if type == 'AddTagFilter'
      items_to_process = items_in_scope
    elsif type == 'DeleteTagFilter' || type == 'ModifyTagFilter'
      items_to_process = FeedItem
                         .joins(:taggings)
                         .where(id: items_in_scope.pluck(:id))
                         .group('feed_items.id,taggings.id')
                         .having('taggings.tag_id=' + tag.id.to_s)
    end

    items_to_process
  end

  # Fix Pundit policy lookup for STI classes that inherit from TagFilter
  def self.policy_class
    TagFilterPolicy
  end

  def as_json(options = {})
    super(options.merge(methods: :type))
  end

  def users
    Role.find_by(authorizable_id: self, authorizable_type: 'TagFilter').try(:users) || User.none
  end
end
