# frozen_string_literal: true
# A RepublishedFeed (aka Remix) contains many InputSource objects that add and remove FeedItem objects. The end result of these additions and removals is an array of FeedItem objects found via the Sunspot search engine.
#
# A RepublishedFeed belongs to a Hub.
#
# Removals take precedence over additions.
#
# Most validations are contained in the ModelExtensions mixin.
#
class RepublishedFeed < ApplicationRecord
  include AuthUtilities
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end

  acts_as_authorization_object
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  attr_accessible :title, :hub_id, :description, :limit, :url_key

  SORTS = %w(date_published title).freeze
  SORTS_FOR_SELECT = [['Date Published', 'date_published'], %w(Title title)].freeze

  belongs_to :hub
  has_many :input_sources, -> { order(created_at: :desc) }, dependent: :destroy

  validates :url_key, uniqueness: true
  validates :url_key, format: { with: /\A[a-z\d\-]+\z/ }

  api_accessible :default do |t|
    t.add :id
    t.add :title
    t.add :hub
    t.add :description
    t.add :created_at
    t.add :updated_at
    t.add :input_sources
  end

  def self.create_with_user(user, hub, params)
    f = new(hub_id: hub.id)
    f.attributes = params[:republished_feed]
    # BUG: By returning nil, this hides the error that prevented the instance from saving
    if f.save
      user.has_role!(:owner, f)
      user.has_role!(:creator, f)
    else
      logger.warn "RepublishedFeed.create_with_user error: #{f.errors.first}"
    end

    f
  end

  # TODO: performance
  def removable_inputs
    result = input_sources.reject { |ins| ins.effect != 'add' }
    if item_search
      result += item_search.results.select { |r| r.input_sources.blank? }.map { |i| InputSource.new(item_source: i, republished_feed: self) }
    end
    result
  end

  def available_inputs
    @available_feeds ||= hub.hub_feeds.map(&:feed).select { |h| !input_sources.map(&:item_source).include?(h) }
    @available_tags ||= ActsAsTaggableOn::Tag.where('id  NOT IN (?)', input_sources.select { |t| t.item_source_type == 'ActsAsTaggableOn::Tag' }.map(&:item_source_id))
    @available_items ||= hub.hub_feeds.map(&:feed_items).flatten.select { |i| !input_sources.map(&:item_source).include?(i) }
    @available_tags + @available_feeds + @available_items
  end

  # All InputSource objects that add FeedItems to this RepublishedFeed.
  def inputs
    input_sources.where(effect: 'add')
  end

  # All InputSource objects that remove FeedItems from this RepublishedFeed.
  def removals
    input_sources.where(effect: 'remove')
  end

  # Create a set of arrays that define additions and removals to create a paginated Sunspot query.
  def item_search
    add_feeds = []
    add_feed_items = []
    add_tags = []
    add_tags_by_users = []

    remove_feeds = []
    remove_feed_items = []
    remove_tags = []
    remove_tags_by_users = []

    return nil if input_sources.blank?

    input_sources.each do |input_source|
      if input_source.effect == 'add'
        case input_source.item_source_type
        when 'Feed'
          add_feeds << input_source.item_source_id
        when 'FeedItem'
          add_feed_items << input_source.item_source_id
        when 'ActsAsTaggableOn::Tag'
          if input_source.created_by_only_id.try :nonzero?
            add_tags_by_users << {
              tag: ActsAsTaggableOn::Tag.find(input_source.item_source_id),
              user: User.find(input_source.created_by_only_id)
            }
          else
            add_tags << ActsAsTaggableOn::Tag.find(input_source.item_source_id)
          end
        when 'SearchRemix'
          add_feed_items << SearchRemix.search_results_for(input_source.item_source_id, limit)
        end
      else
        case input_source.item_source_type
        when 'Feed'
          remove_feeds << input_source.item_source_id
        when 'FeedItem'
          remove_feed_items << input_source.item_source_id
        when 'ActsAsTaggableOn::Tag'
          if input_source.created_by_only_id.try :nonzero?
            remove_tags_by_users << {
              tag: ActsAsTaggableOn::Tag.find(input_source.item_source_id),
              user: User.find(input_source.created_by_only_id)
            }
          else
            remove_tags << ActsAsTaggableOn::Tag.find(input_source.item_source_id)
          end
        end
      end
    end

    add_feed_items.flatten!
    add_feed_items.uniq!

    search = FeedItem.search(include: [:tags, :taggings, :feeds, :hub_feeds]) do
      any_of do
        with(:feed_ids, add_feeds) unless add_feeds.blank?
        with(:id, add_feed_items) unless add_feed_items.blank?
        unless add_tags.blank?
          with(:tag_contexts, add_tags.collect { |t| "hub_#{hub_id}-#{t.name}" })
        end
        unless add_tags_by_users.blank?
          with(:tag_contexts_by_users, add_tags_by_users.collect { |t| "hub_#{hub_id}-#{t[:tag].name}-user_#{t[:user].id}" })
        end
      end
      any_of do
        without(:feed_ids, remove_feeds) unless remove_feeds.blank?
        without(:id, remove_feed_items) unless remove_feed_items.blank?
        unless remove_tags.blank?
          without(:tag_contexts, remove_tags.collect { |t| "hub_#{hub_id}-#{t.name}" })
        end
        unless remove_tags_by_users.blank?
          without(:tag_contexts_by_users, remove_tags_by_users.collect { |t| "hub_#{hub_id}-#{t[:tag].name}-user_#{t[:user].id}" })
        end
      end
      order_by('date_published', :desc)
      paginate per_page: limit, page: 1
    end

    search
  end

  delegate :to_s, to: :title

  def self.title
    'Remixed feed'
  end
end
