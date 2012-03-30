# A FeedItem is an individual bit of content that's gotten into TagTeam via a Feed or the bookmarklet. It can belong to many Feeds, has many ActsAsTaggableOn::Tag objects, and uses a subset of Dublin Core metadata to track it's info.
#
# A FeedItem belongs to a Hub through the HubFeed model, which means a FeedItem can belong to multiple Hubs as well. It has a separate tag context for every Hub, which is a pre-calculated tag list with the filters applied within that Hub. This means a FeedItem can have a separate set of tags for every Hub it appears in after filters are applied.
#
# A FeedItem is unique on its url.
#
# A FeedItem can belong to one or more FeedRetrieval objects if more than one Feed contains this item.
#
#
# Most validations are contained in the ModelExtensions mixin.
#
class FeedItem < ActiveRecord::Base
  acts_as_taggable
  acts_as_authorization_object
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end
  include ModelExtensions

  before_validation do
    auto_sanitize_html(:content, :description)
    auto_truncate_columns(:title,:url,:guid,:authors,:contributors,:description,:content,:rights)
  end

  attr_accessible :title, :url, :guid, :authors, :contributors, :description, :content, :rights, :date_published, :last_updated
  attr_accessor :hub_id, :bookmark_collection_id
  
  # Necessary because we don't want to pass the huge content
  # column over the wire if we don't need to.
  def self.columns_for_line_item
    [:id,:date_published, :title, :url, :guid, :authors, :last_updated]
  end

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
    t.add :tag_context_hierarchy, :as => :tags
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
    t.add :tag_context_hierarchy, :as => :tags
    t.add :description
    t.add :content
  end

  searchable do
    text :title, :more_like_this => true
    text :description, :more_like_this => true
    text :content, :more_like_this => true
    text :url, :more_like_this => true
    text :guid, :more_like_this => true
    text :authors, :more_like_this => true
    text :contributors, :more_like_this => true
    text :rights, :more_like_this => true
    text :tag_list, :more_like_this => true
    integer :hub_ids, :multiple => true
    integer :hub_feed_ids, :multiple => true
    integer :id

    integer :feed_ids, :multiple => true
    string :tag_list, :multiple => true
    string :tag_contexts, :multiple => true

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

  # An array of all tag contexts for every tagging on this item.
  def tag_contexts
    self.taggings.collect{|tg| "#{tg.context}-#{tg.tag_id}"}
  end

  # A hash of arrays of tag contexts - used for the API.
  def tag_context_hierarchy
    tags_for_api = {}
    self.taggings.collect do|tg|
      tags_for_api[tg.context].nil? ? (tags_for_api[tg.context] = []) : ''
      tags_for_api[tg.context] << tg.tag.name
    end
    tags_for_api
  end

  validates_uniqueness_of :url

  has_and_belongs_to_many :feed_retrievals
  has_and_belongs_to_many :feeds
  has_many :hub_feeds, :through => :feeds
  has_many :hub_feed_item_tag_filters, :dependent => :destroy, :order => :position
  has_many :input_sources, :dependent => :destroy, :as => :item_source
  after_save :reindex_all_tags

  # Reindex all taggings on all facets into solr.
  def reindex_all_tags
    self.taggings.collect{|tg| tg.tag}.uniq.collect{|t| t.index}
  end

  def self.descriptive_name
    'Feed Item'
  end

  # Find the first HubFeed for this item in a Hub. Used for display within search results, tags, and other areas where the HubFeed context doesn't exist.
  def hub_feed_for_hub(hub_id)
    hub_feeds.reject{|hf| hf.hub_id != hub_id}.uniq.compact.first
  end

  # The hubs for this item as found through its HubFeeds.
  def hubs
    # TODO Optimize via multi-table joins
    hf = self.hub_feeds
    (hf.empty?) ? [] : hf.collect{|hf| hf.hub}.flatten.uniq.compact
  end

  def hub_ids
    (self.hubs.empty?) ? [] : self.hubs.collect{|h| h.id}
  end

  # Re-render all tag facets for this FeedItem.
  def update_filtered_tags
    hs = self.hubs
    hs.each do |h|
      self.render_filtered_tags_for_hub(h)
    end
    self.save
  end

  # Re-render tag facets by applying filters but only for this Hub.
  def render_filtered_tags_for_hub(hub = Hub.first)
    #"tag_list" is the source list of tags directly from RSS/Atom feeds.
    tag_list_for_filtering = self.tag_list.dup

    #Hub tags
    if ! hub.hub_tag_filters.blank?
      hub.hub_tag_filters.each do|htf|
        htf.filter.act(tag_list_for_filtering)
      end
    end

    #Hub feed tags
    hfs = self.hub_feeds(hub)
    hfs.each do|hf|
      if ! hf.hub_feed_tag_filters.blank?
        hf.hub_feed_tag_filters.each do |hftf|
          hftf.filter.act(tag_list_for_filtering)
        end
      end
    end
    #Hub feed item filters
    self.hub_feed_item_tag_filters.find(:all, :conditions => {:hub_id => hub.id, :feed_item_id => self.id}, :order => :position).each do|hfitf|
      hfitf.filter.act(tag_list_for_filtering)
    end
    self.set_tag_list_on("hub_#{hub.id}".to_sym, tag_list_for_filtering.join(','))
    tag_list_for_filtering
  end

  def to_s
    "#{title}"
  end

  alias :display_title :to_s

  # Used to emit this FeedItem as an array when it's included in at RepublishedFeed.
  def items(not_needed)
    [self]
  end

  def mini_icon
    %q|<span class="ui-silk inline ui-silk-application-view-list"></span>|
  end

  # Used during the Feed#update_feed spidering process to de-duplicate and create a FeedItem if it doesn't exist. Tags from all sources are merged into a FeedItem. Changes are tracked and saved on the FeedRetrieval object passed into this method. If there are changes, a Resque job is created to re-calculate tag facets.
  def self.create_or_update_feed_item(feed,item,feed_retrieval)
    fi = FeedItem.find_or_initialize_by_url(:url => item.link)
    item_changelog = {}

    fi.title = item.title
    fi.description = item.summary

    if fi.new_record?
      # Instantiate only for new records.
      fi.guid = item.guid
      fi.authors = item.author
      fi.contributors = item.contributor

      fi.description = item.summary
      fi.content = item.content
      fi.rights = item.rights
      if ! item.published.blank? && item.published.year >= 1900
        fi.date_published = item.published.to_datetime
      end
      if ! item.last_updated.blank? && item.last_updated.year >= 1900
        fi.last_updated = item.last_updated.to_datetime
      end
      # logger.warn('dirty because there is a new feed_item')
      item_changelog[:new_record] = true
      feed.dirty = true
    end
    fi.feed_retrievals << feed_retrieval
    fi.feeds << feed unless fi.feeds.include?(feed)
    # Merge tags. . .
    pre_update_tags = fi.tag_list.dup.sort
    # Merge the existing and the new tags together, assign to the it's tag list, uniquify and join
    # Autotruncate tags to be no longer than 255 characters. This would be better done at the model level.
    fi.tag_list = [fi.tag_list,item.categories.collect{|t| t.downcase[0,255].gsub(/,/,'_').strip}].flatten.uniq
    if pre_update_tags != fi.tag_list.sort
      # logger.warn('dirty because tags have changed')
      feed.dirty = true
      unless fi.new_record?
        # Be sure to update the feed changelog here in case
        # an item only has tag changes.
        item_changelog[:tags] = [pre_update_tags, fi.tag_list]
        feed.changelog[fi.id] = item_changelog
      end
    end
    if fi.valid?
      if feed.changelog.keys.include?(fi.id) or fi.new_record?
        # This runs here because we're auto stripping and auto-truncating columns and
        # want the change tracking to be relative to these fixed values.
        # logger.warn('dirty because a feed item changed or was created.')
        # logger.warn('dirty Changes: ' + fi.changes.inspect)
        unless fi.new_record?
          item_changelog.merge!(fi.changes)
        end
        # logger.warn('dirty item_changelog: ' + item_changelog.inspect)
        feed.dirty = true
        fi.save
        feed.changelog[fi.id] = item_changelog
        Resque.enqueue(FeedItemTagRenderer, fi.id)
      end
    else
      # logger.warn("Couldn't auto create feed_item: #{fi.errors.inspect}")
    end

  end

end
