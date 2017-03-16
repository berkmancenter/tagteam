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

  VALID_SCOPE_TYPES = %w(Hub HubFeed FeedItem).freeze
  validates :tag_id, presence: true
  validates :scope_type, inclusion: { in: VALID_SCOPE_TYPES }
  validates :tag_id, uniqueness: { scope: [:scope_type, :scope_id],
                                   message: 'Filter conflicts with existing filter.' }

  attr_accessible :tag_id

  acts_as_authorization_object
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :tag
  end

  scope :applied, -> { where(applied: true) }

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

  def rollback_and_destroy_async
    DestroyTagFilter.perform_async(id)
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

  # Informing taggers about changes in their tags
  def notify_taggers(old_tag, new_tag, scope, hub, hub_feed, current_user)
    logger.info('Trying to nofity about changes in tags')

    case scope.class.name
    when 'Hub'
      tag_filters = TagFilter.where(
        hub_id: hub,
        tag_id: old_tag,
        type: 'AddTagFilter'
      )
    when 'HubFeed'
      hub_feed_tag_filters = TagFilter.where(
        hub_id: hub,
        tag_id: old_tag,
        scope_type: 'HubFeed',
        scope_id: hub_feed,
        type: 'AddTagFilter'
      )

      feed_item_tag_filters = TagFilter
                              .joins('LEFT JOIN feed_items_feeds on tag_filters.scope_id = feed_items_feeds.feed_item_id')
                              .where(
                                feed_items_feeds: {
                                  feed_id: hub_feed
                                },
                                hub_id: hub,
                                tag_id: old_tag,
                                scope_type: 'FeedItem'
                              )

      tag_filters = hub_feed_tag_filters + feed_item_tag_filters
    when 'FeedItem'
      return
    end

    taggers_to_notify = []
    tag_filters.each do |tag_filter|
      taggers_to_notify.concat(Role.where(
        authorizable_id: tag_filter,
        authorizable_type: 'TagFilter'
      ).first.users)
    end

    taggers_to_notify = taggers_to_notify.uniq - [current_user]

    unless taggers_to_notify.empty?
      Notifications.tag_change_notification(
        taggers_to_notify,
        hub,
        old_tag,
        new_tag,
        current_user
      ).deliver_later
    end
  end

  # Informing taggers about changes in their items
  def notify_about_items_modification(hub, current_user)
    logger.info('Trying to nofity about changes in items')

    # Get configs for notifications
    hub_user_notifications_setup = HubUserNotification.where(hub_id: hub)

    # loop through scoped items
    items_in_scope.each do |modified_item|
      users_to_notify = []
      tag_filters_applied = TagFilter.where(
        id: modified_item.taggings.pluck(:tagger_id)
      )

      # find and match filters owners
      tag_filters_applied.each do |tag_filter|
        users_to_notify.concat(Role.where(
          authorizable_id: tag_filter,
          authorizable_type: 'TagFilter'
        ).first.users)
      end

      users_to_notify_allowed = []
      users_to_notify = users_to_notify.uniq - [current_user]
      users_to_notify.each do |user|
        user_setup = hub_user_notifications_setup.select do |setup|
          setup.user_id == user.id
        end

        # check if a user wants to reveive notifications
        if !user_setup.empty? && user_setup.first.notify_about_modifications
          users_to_notify_allowed << user
        end
      end

      unless users_to_notify_allowed.empty?
        Notifications.item_change_notification(
          hub,
          modified_item,
          users_to_notify_allowed,
          current_user
        ).deliver_later
      end
    end
  end

  # Fix Pundit policy lookup for STI classes that inherit from TagFilter
  def self.policy_class
    TagFilterPolicy
  end
end
