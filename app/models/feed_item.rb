# frozen_string_literal: true
# A FeedItem is an individual bit of content that's gotten into TagTeam via
# a Feed or the bookmarklet. It can belong to many Feeds, has many
# ActsAsTaggableOn::Tag objects, and uses a subset of Dublin Core metadata to
# track it's info.
#
# A FeedItem belongs to a Hub through the HubFeed model, which means a FeedItem
# can belong to multiple Hubs as well. It has a separate tag context for every
# Hub, which is a pre-calculated tag list with the filters applied within that
# Hub. This means a FeedItem can have a separate set of tags for every Hub it
# appears in after filters are applied.
#
# A FeedItem is unique on its url.
#
# A FeedItem can belong to one or more FeedRetrieval objects if more than one
# Feed contains this item.
#
# Most validations are contained in the ModelExtensions mixin.

class FeedItem < ApplicationRecord
  include ModelExtensions
  include TagScopable

  acts_as_taggable
  acts_as_authorization_object
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  before_create :set_image_url

  before_validation do
    auto_sanitize_html(:content, :description)
    auto_truncate_columns(:title, :url, :guid, :authors, :contributors,
                          :description, :content, :rights)
  end
  validates :url, uniqueness: true

  has_and_belongs_to_many :feed_retrievals, join_table: 'feed_items_feed_retrievals'
  has_and_belongs_to_many :feeds
  has_many :hub_feeds, through: :feeds
  has_many :hubs, through: :hub_feeds
  has_many :input_sources, dependent: :destroy, as: :item_source

  attr_accessible :title, :url, :guid, :authors, :contributors,
                  :description, :content, :rights, :date_published, :last_updated
  attr_accessor :hub_id, :bookmark_collection_id

  api_accessible :default do |t|
    t.add :id
    t.add :title
    t.add :url
    t.add :guid
    t.add :authors
    t.add :hub_ids
    t.add :hub_feed_ids
    t.add :date_published
    t.add :last_updated
    t.add :tag_context_hierarchy, as: :tags
  end

  api_accessible :with_content do |t|
    t.add :id
    t.add :title
    t.add :url
    t.add :guid
    t.add :authors
    t.add :hub_ids
    t.add :hub_feed_ids
    t.add :date_published
    t.add :last_updated
    t.add :tag_context_hierarchy, as: :tags
    t.add :description
    t.add :content
  end

  searchable do
    text :title, more_like_this: true
    text :description, more_like_this: true
    text :content, more_like_this: true
    text :url, more_like_this: true
    text :guid, more_like_this: true
    text :authors, more_like_this: true
    text :contributors, more_like_this: true
    text :rights, more_like_this: true
    text :tag_list, using: :tag_list_string_for_indexing, more_like_this: true
    integer :hub_ids, multiple: true
    integer :hub_feed_ids, multiple: true
    integer :id

    integer :feed_ids, multiple: true
    string :tag_list, using: :tag_list_array_for_indexing, multiple: true
    string :tag_contexts, multiple: true
    string :tag_contexts_by_users, multiple: true

    string :title
    string :url
    string :guid
    string :authors
    string :contributors
    string :description
    string :rights
    time :date_published
    time :last_updated
  end

  def taggable_items
    # We want to return an ActiveRecord object
    FeedItem.where(id: id)
  end

  def apply_tag_filters(hub_ids = [])
    # So we can pass a single hub id
    hub_ids = [hub_ids] unless hub_ids.respond_to? :each
    hubs = hub_ids.empty? ? self.hubs : Hub.where(id: hub_ids)

    hubs.each do |hub|
      hub.tag_filters.order('updated_at ASC').each do |filter|
        filter.apply(items: FeedItem.where(id: id))
      end
    end
  end

  # An array of all tag contexts for every tagging on this item.
  def tag_contexts
    taggings.collect do |tg|
      "#{tg.context}-#{tg.tag.name}" unless tg.context.eql? 'tags'
    end.compact
  end

  def tag_contexts_by_users
    taggings.collect do |tg|
      next if tg.context.eql? 'tags'

      if tg.tagger_type.eql? 'User'
        auth_user = User.where(id: tg.tagger_id).first
      else
        role = Role.where(
          authorizable_id: tg.tagger_id,
          authorizable_type: 'TagFilter',
          name: 'creator'
        ).first

        next if role.nil?

        auth_user = role.users.first
      end

      next if auth_user.nil?

      "#{tg.context}-#{tg.tag.name}-user_#{auth_user.id}"
    end.compact
  end

  # A hash of arrays of tag contexts - used for the API.
  def tag_context_hierarchy
    tags_for_api = {}
    taggings.collect do |tg|
      tags_for_api[tg.context].nil? ? (tags_for_api[tg.context] = []) : ''
      tags_for_api[tg.context] << tg.tag.name
    end
    tags_for_api
  end

  # Reindex all taggings on all facets into solr.
  def reindex_all_tags
    tags_of_concern = taggings.collect(&:tag_id).uniq
    ActsAsTaggableOn::Tag.where(id: tags_of_concern)
                         .solr_index(include: :taggings, batch_commit: false)
  end

  # Find the first HubFeed for this item in a Hub. Used for display within
  # search results, tags, and other areas where the HubFeed context doesn't
  # exist.
  def hub_feed_for_hub(hub_id)
    hub_feeds.reject { |hf| hf.hub_id != hub_id }.uniq.compact.first
  end

  def tag_list_array_for_indexing
    # tag_list as provided by ActsAsTaggableOn always does a sql query.
    # Construct the tag list correctly.
    tags.collect(&:name)
  end

  def tag_list_string_for_indexing
    # tag_list as provided by ActsAsTaggableOn always does a sql query.
    # Construct the tag list correctly.
    tags.collect(&:name).join(', ')
  end

  def to_s
    (title.blank? ? 'untitled' : title).to_s
  end

  alias display_title to_s

  def self.title
    'RSS feed item'
  end

  # Used to emit this FeedItem as an array when it's included in at RepublishedFeed.
  def items(_not_needed)
    [self]
  end

  def mini_icon
    '<span class="ui-silk inline ui-silk-application-view-list"></span>'
  end

  def add_tags(new_tags, context, tagger)
    # Merge the existing and the new tags together. When new tags conflict with
    # existing tags, new tags win.

    new_taggings = new_tags.map do |new_tag|
      ActsAsTaggableOn::Tagging.new(
        tag: ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(new_tag),
        taggable: self,
        tagger: tagger,
        context: context
      )
    end

    new_taggings.each do |tagging|
      deactivated_taggings = tagging.deactivate_taggings!
      tagging.save!
      deactivated_taggings.each do |deactivated_tagging|
        deactivated_tagging.deactivator = tagging
        deactivated_tagging.save!
      end
    end
  end

  # Used during the Feed#update_feed spidering process to de-duplicate and
  # create a FeedItem if it doesn't exist. Tags from all sources are merged
  # into a FeedItem. Changes are tracked and saved on the FeedRetrieval object
  # passed into this method. If there are changes, a Resque job is created to
  # re-calculate tag facets.
  def self.create_or_update_feed_item(feed, item, feed_retrieval)
    fi = FeedItem.find_or_initialize_by(url: item.link)
    item_changelog = {}

    fi.title = item.title
    fi.description = item.summary unless item.summary.blank?
    if fi.new_record?
      # Instantiate only for new records.
      fi.guid = item.guid
      fi.authors = item.author
      fi.contributors = item.contributor

      fi.description = item.summary
      fi.content = item.content
      fi.rights = item.rights
      if !item.published.blank? && item.published.year >= 1900
        fi.date_published = item.published.to_datetime
      end
      if !item.updated.blank? && item.updated.year >= 1900
        fi.last_updated = item.updated.to_datetime
      end
      # logger.warn('dirty because there is a new feed_item')
      item_changelog[:new_record] = true
      feed.dirty = true
    end
    fi.feed_retrievals << feed_retrieval
    fi.feeds << feed unless fi.feeds.include?(feed)

    # Merge tags...
    new_tags = item.categories.map do |tag|
      ActsAsTaggableOn::Tag.normalize_name(tag)
    end
    new_tags.sort_by!(&:to_s)
    new_tags.uniq!(&:to_s)

    tag_context = Rails.application.config.global_tag_context
    old_tags = fi.all_tags_list_on(tag_context).dup.sort

    if new_tags != old_tags
      fi.add_tags(new_tags, tag_context, feed)

      # logger.warn('dirty because tags have changed')
      feed.dirty = true
      unless fi.new_record?
        # Be sure to update the feed changelog here in case
        # an item only has tag changes.
        item_changelog[:tags] = [old_tags, fi.all_tags_list_on(tag_context)]
        feed.changelog[fi.id] = item_changelog
      end
    end

    if fi.valid?
      if feed.changelog.keys.include?(fi.id) || fi.new_record?
        # This runs here because we're auto stripping and auto-truncating
        # columns and want the change tracking to be relative to these fixed
        # values.
        # logger.warn('dirty because a feed item changed or was created.')
        # logger.warn('dirty Changes: ' + fi.changes.inspect)
        item_changelog.merge!(fi.changes) unless fi.new_record?
        # logger.warn('dirty item_changelog: ' + item_changelog.inspect)
        feed.dirty = true
        fi.save
        feed.changelog[fi.id] = item_changelog
      end
    end
  end

  # Necessary because we don't want to pass the huge content
  # column over the wire if we don't need to.
  def self.columns_for_line_item
    [:id, :date_published, :title, :image_url, :url,
     :guid, :authors, :last_updated]
  end

  def self.tag_counts_on(context)
    ActsAsTaggableOn::Tag.find_by_sql([
                                        'SELECT tags.*, count(*)
                                        FROM tags JOIN taggings ON taggings.tag_id = tags.id
                                        WHERE taggings.context = ? AND taggings.taggable_type = ?
                                        GROUP BY tags.id', context, name
                                      ])
  end

  def self.tag_counts_on_items(item_ids, context = nil)
    query = ActsAsTaggableOn::Tag.select('tags.*, count(*)').joins(:taggings)
                                 .where(taggings: { taggable_id: item_ids, taggable_type: name })
                                 .group('tags.id')
    query = query.where(taggings: { context: context }) if context
    query
  end

  def self.apply_tag_filters(item_id, hub_ids = [])
    feed_item = find(item_id)
    feed_item.apply_tag_filters(hub_ids)
  end

  # Informing taggers about changes in their items
  def notify_about_items_modification(hub, current_user, items_to_process_joined, changes)
    # Get configs for notifications
    hub_user_notifications_setup = HubUserNotification.where(hub_id: hub)

    # tag filter creators
    users_to_notify = []
    tag_filters_applied = TagFilter.where(
      id: taggings.where(
        tagger_type: 'TagFilter'
      ).pluck(:tagger_id)
    )

    # find and match filters owners
    tag_filters_applied.each do |tag_filter|
      users_to_notify.concat(Role.where(
        authorizable_id: tag_filter,
        authorizable_type: 'TagFilter'
      ).first.users)
    end

    # simple taggers
    taggings = ActsAsTaggableOn::Tagging.where(
      tagger_type: 'User',
      taggable_id: id,
      taggable_type: 'FeedItem',
      context: 'hub_' + hub.id.to_s
    )

    users_to_notify += User.where(
      id: taggings.pluck(:tagger_id)
    )

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
        self,
        users_to_notify_allowed,
        current_user,
        changes
      ).deliver_later
    end
  end

  private

  def parse_out_image_url
    src = nil
    unless description.nil? || description.empty? || description.index('<img').nil?
      doc = Nokogiri::HTML(description)
      src = pick_image_src(doc)
    end

    unless src || content.nil? || content.empty? || content.index('<img').nil?
      doc = Nokogiri::HTML(content)
      src = pick_image_src(doc)
    end
    src
  end

  def pick_image_src(doc)
    images = doc.css('img')
    image_widths = images.map { |i| i['width'] ? i['width'].to_i : nil }
    max_width = image_widths.compact.max
    # if we have a width greater than 150, return that image
    if max_width && max_width > 150
      i = image_widths.index(max_width)
      return images[i]['src']
    end
    # if some of the images don't have widths, pick one randomly
    # because we don't know their widths, and picking the first
    # often ends up with icons
    nil_indices = image_widths.map.with_index { |w, j| j if w.nil? }.compact
    return images[nil_indices.sample]['src'] if nil_indices.count > 0
  end

  def set_image_url
    image_url = parse_out_image_url
    if image_url
      self.content = content.gsub(/[[:cntrl:]]/, '') if content
      self.description = description.gsub(/[[:cntrl:]]/, '') if description
      self.image_url = image_url
    end
  end
end
