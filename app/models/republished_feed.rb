# A RepublishedFeed (aka Remix) contains many InputSource objects that add and remove FeedItem objects. The end result of these additions and removals is an array of FeedItem objects found via the Sunspot search engine.
#
# A RepublishedFeed belongs to a Hub.
#
# Removals take precedence over additions.
# 
# Most validations are contained in the ModelExtensions mixin.
#
class RepublishedFeed < ActiveRecord::Base

  include AuthUtilities
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end

  acts_as_authorization_object
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  attr_accessible :title, :hub_id, :description, :limit, :url_key

  SORTS = ['date_published', 'title']
  SORTS_FOR_SELECT = [['Date Published','date_published' ],['Title', 'title']]

  belongs_to :hub
  has_many :input_sources, :dependent => :destroy, :order => 'created_at desc' 

  validates_uniqueness_of :url_key
  validates_format_of :url_key, :with => /^[a-z\d\-]+/

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
    f = new(:hub_id => hub.id)
    f.attributes = params[:republished_feed]
    if f.save
      user.has_role!(:owner, f)
      user.has_role!(:creator, f)
      f
    else
      nil
    end
  end

  #todo performance
  def removable_inputs
    result = self.input_sources.reject{|ins| ins.effect != 'add'} 
    if self.item_search
      result += self.item_search.results.select {|r| r.input_sources.blank? }.map{|i| InputSource.new(:item_source => i, :republished_feed => self)}
    end
    result
  end

  def available_inputs
    @available_feeds ||= self.hub.hub_feeds.map(&:feed).select {|h| !self.input_sources.map(&:item_source).include?(h) }
    @available_tags ||= ActsAsTaggableOn::Tag.where('id  NOT IN (?)', self.input_sources.select {|t| t.item_source_type == 'ActsAsTaggableOn::Tag' }.map(&:item_source_id))
    @available_items ||= self.hub.hub_feeds.map(&:feed_items).flatten.select {|i| !self.input_sources.map(&:item_source).include?(i)}
    @available_tags + @available_feeds + @available_items 
  end

  # All InputSource objects that add FeedItems to this RepublishedFeed.
  def inputs
    input_sources.where(:effect => 'add') 
  end

  # All InputSource objects that remove FeedItems from this RepublishedFeed.
  def removals
    input_sources.where(:effect => 'remove') 
  end

  # Create a set of arrays that define additions and removals to create a paginated Sunspot query.
  def item_search

    add_feeds = []
    add_feed_items = []
    add_tags = []

    remove_feeds = []
    remove_feed_items = []
    remove_tags = []

    if self.input_sources.blank?
      return nil
    end

    self.input_sources.each do|input_source|
      if input_source.effect == 'add'
          case input_source.item_source_type
          when 'Feed'
              add_feeds << input_source.item_source_id
          when 'FeedItem'
              add_feed_items << input_source.item_source_id
          when 'ActsAsTaggableOn::Tag'
              add_tags << ActsAsTaggableOn::Tag.find(input_source.item_source_id)
          when 'SearchRemix' 
              add_feed_items << SearchRemix.search_results_for(input_source.item_source_id)
          end
      else
          case input_source.item_source_type
          when 'Feed'
              remove_feeds << input_source.item_source_id
          when 'FeedItem'
              remove_feed_items << input_source.item_source_id
          when 'ActsAsTaggableOn::Tag'
              remove_tags << ActsAsTaggableOn::Tag.find(input_source.item_source_id)
          end
      end
    end

    add_feed_items.flatten!
    add_feed_items.uniq!

    search = FeedItem.search(:include => [:tags, :taggings, :feeds, :hub_feeds]) do
      any_of do
        unless add_feeds.blank?
          with(:feed_ids, add_feeds)
        end
        unless add_feed_items.blank?
          with(:id, add_feed_items)
        end
        unless add_tags.blank?
          with(:tag_contexts, add_tags.collect{|t| "hub_#{self.hub_id}-#{t.name}"})
        end
      end
      any_of do
        unless remove_feeds.blank?
          without(:feed_ids, remove_feeds)
        end
        unless remove_feed_items.blank?
          without(:id, remove_feed_items)
        end
        unless remove_tags.blank?
          without(:tag_contexts, remove_tags.collect{|t| "hub_#{self.hub_id}-#{t.name}"})
        end
      end
      order_by('date_published', :desc)
      paginate :per_page => self.limit, :page => 1
    end

    search

  end

  def to_s
    "#{title}"
  end

  def self.title
    'Remixed feed'
  end

end
