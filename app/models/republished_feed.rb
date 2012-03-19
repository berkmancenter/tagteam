# A RepublishedFeed (aka Remix) contains many InputSource objects that add and remove FeedItem objects. The end result of these additions and removals is an array of FeedItem objects found via the Sunspot search engine.
#
# A RepublishedFeed belongs to a Hub.
#
# Removals take precedence over additions.
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

  attr_accessible :title, :hub_id, :description, :limit

  SORTS = ['date_published', 'title']
  SORTS_FOR_SELECT = [['Date Published','date_published' ],['Title', 'title']]

  belongs_to :hub
  has_many :input_sources, :dependent => :destroy, :order => :position 

  api_accessible :default do |t|
    t.add :id
    t.add :title
    t.add :hub
    t.add :description
    t.add :created_at
    t.add :updated_at
    t.add :input_sources
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
        if input_source.item_source_type == 'Feed'
          add_feeds << input_source.item_source_id

        elsif input_source.item_source_type == 'FeedItem'
          add_feed_items << input_source.item_source_id

        else
          add_tags << input_source.item_source_id
        end

      else
        if input_source.item_source_type == 'Feed'
          remove_feeds << input_source.item_source_id

        elsif input_source.item_source_type == 'FeedItem'
          remove_feed_items << input_source.item_source_id

        else
          remove_tags << input_source.item_source_id
        end

      end
    end

    search = FeedItem.search(:include => [:tags, :taggings, :feeds, :hub_feeds]) do
      any_of do
        unless add_feeds.blank?
          with(:feed_ids, add_feeds)
        end
        unless add_feed_items.blank?
          with(:id, add_feed_items)
        end
        unless add_tags.blank?
          with(:tag_contexts, add_tags.collect{|t| "hub_#{self.hub_id}-#{t}"})
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
          without(:tag_contexts, remove_tags.collect{|t| "hub_#{self.hub_id}-#{t}"})
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

end
