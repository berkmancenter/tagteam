# frozen_string_literal: true
class TagFilter < ApplicationRecord
  include AuthUtilities
  include ModelExtensions

  belongs_to :hub, optional: true
  belongs_to :scope, polymorphic: true, optional: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', optional: true
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag', optional: true
  has_many :taggings, as: :tagger, class_name: 'ActsAsTaggableOn::Tagging'
  has_many :deactivated_taggings, as: :tagger
  has_many :self_deactivated_taggings, class_name: 'DeactivatedTagging',
                                         as: :deactivator

  VALID_SCOPE_TYPES = %w(Hub HubFeed FeedItem).freeze
  validates :tag_id, presence: true
  validates :scope_type, inclusion: { in: VALID_SCOPE_TYPES }
  validates :tag_id, uniqueness: { scope: [:scope_type, :scope_id, :type],
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

  def filtered_feed_items
    return [self.scope] if self.scope.is_a?(FeedItem)

    return FeedItem.find(DeactivatedTagging.where(deactivator_id: self.id, deactivator_type: 'TagFilter').map(&:taggable_id).uniq) if self.scope.is_a?(Hub)
    return []
  end

  def next_to_apply?
    applied == false &&
      (hub.tag_filters_before(self).count ==
        hub.tag_filters_before(self).applied.count) &&
      (hub.tag_filters_after(self).applied.count == 0)
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

  def rollback_and_destroy(current_user, async = true)
    if async
      TagFilters::DestroyJob.perform_later(self, current_user)
    else
      # TagFilter::DestroyJob.perform_now still puts this into a queue and the page loads
      # before it's done, so we are pulling it out of queue
      self.queue_destroy_notification(current_user)
      self.rollback
      self.destroy
    end
  end

  def queue_destroy_notification(updater)
    changes = case self.class.to_s
      when 'AddTagFilter'
        { type: 'tags_deleted', values: [self.tag_name] }
      when 'DeleteTagFilter'
        { type: 'tags_added', values: [self.tag_name] }
      when 'ModifyTagFilter'
        { type: 'tags_modified', values: [[self.new_tag_name], [self.tag_name]] }
      when 'SupplementTagFilter'
        { type: 'tags_supplemented_deletion', values: [[self.tag_name, self.new_tag_name]] }
      end

    TaggingNotifications::SendNotificationJob.perform_later(
        self.hub,
        self.filtered_feed_items,
        [self],
        updater,
        [changes]
      )
  end

  # End API for filters,
  # but this calls model override for ModifyTagFilter
  def deactivate_taggings!(item_ids)
    deactivates_taggings(item_ids).find_each { |tagging| deactivate_tagging(tagging) }
  end

  # Somewhat surprisingly, this code is the same for the add and delete
  # filters. In the add filter, it deactivates what would be duplicate
  # taggings. In the delete filter, it deactivates the taggings it's supposed
  # to.
  #
  # For example, if hub filter adds 'tag1', and now we create a feed filter
  # that adds 'tag1', all the 'tag1' tags for items in this feed should be
  # owned by the feed filter.
  def deactivates_taggings(item_ids)
    # Deactivates any taggings that are the same except in owner, and do not
    # deactivate own taggings.
    return ActsAsTaggableOn::Tagging.where('1=2') if item_ids.empty?

    ActsAsTaggableOn::Tagging
      .where(context: hub.tagging_key, tag_id: tag.id,
             taggable_type: 'FeedItem', taggable_id: item_ids)
      .where('("taggings"."tagger_id" IS NULL AND ' \
            '"taggings"."tagger_type" IS NULL) OR ' \
            '(NOT ("taggings"."tagger_id" = ? AND "taggings"."tagger_type" = ?))',
             id, self.class.base_class.name)
  end

  def deactivate_tagging(tagging)
    deactivated = DeactivatedTagging.new
    tagging.attributes.each do |key, value|
      deactivated.send("#{key}=", value)
    end

    deactivated.deactivator = self unless new_record?

    DeactivatedTagging.transaction do
      deactivated.save!
      tagging.destroy
    end

    deactivated
  end

  def reactivates_taggings
    self_deactivated_taggings
  end

  def reactivate_taggings!
    reactivates_taggings.each(&:reactivate)
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

  def self.apply_hub_filters(hub, feed_item)
    hub_feed = hub.hub_feed_for_feed_item(feed_item)
    filters = TagFilter.where("(scope_type = 'Hub' AND scope_id = #{hub.id}) OR (scope_type = 'HubFeed' AND scope_id = #{hub_feed.id})").order("created_at ASC")
    applied_tag_ids = ActsAsTaggableOn::Tagging.where(taggable_id: feed_item.id).where("context <= 'hub_#{hub.id}'").map(&:tag_id)
    applied_tags = ActsAsTaggableOn::Tag.where(id: applied_tag_ids)

    filters.each do |filter|
      # apply tag filter if item has tag for certain filter types
      # apply tag filter for all AddTagFilters
      if filter.type == 'DeleteTagFilter' && applied_tag_ids.include?(filter.tag_id)
        filter.apply([feed_item.id])
        applied_tag_ids.reject! { |tag_id| tag_id == filter.tag_id }
      elsif filter.type == 'ModifyTagFilter'
        filter_tag_name = ActsAsTaggableOn::Tag.find(filter.tag_id).name
        if filter_tag_name.include?('*')
          queried_tag_name = filter_tag_name.tr('*', '%')
          filter_applied_tags = applied_tags
                                .where('name LIKE ?', queried_tag_name)

          next if filter_applied_tags.count.zero?
        else
          next unless applied_tag_ids.include?(filter.tag_id)
        end

        filter.apply([feed_item.id])
        applied_tag_ids.reject! { |tag_id| tag_id == filter.tag_id }
        applied_tag_ids << filter.new_tag_id
      elsif filter.type == 'SupplementTagFilter' && applied_tag_ids.include?(filter.tag_id) && !applied_tag_ids.include?(filter.new_tag_id)
        filter.apply([feed_item.id])
        applied_tag_ids << filter.new_tag_id
      elsif filter.type == 'AddTagFilter'
        filter.apply([feed_item.id])
        applied_tag_ids << filter.tag_id
      end
    end
  end

  def self.find_recursive(hub_id, tag_name, filter = nil)
    tag = ActsAsTaggableOn::Tag.find_by_name_normalized(tag_name)
    return filter if tag.nil?

    new_filter = self.where(scope_type: 'Hub', scope_id: hub_id, tag_id: tag.id).where.not(type: 'SupplementTagFilter')
    return filter if new_filter.empty?
    return new_filter.first if new_filter.first.type == 'DeleteTagFilter'

    find_recursive(hub_id, new_filter.first.new_tag.name, new_filter.first)
  end
end
