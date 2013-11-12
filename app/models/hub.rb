# A Hub is the highest level of organization in TagTeam. It has many HubFeed objects containing FeedItems. These FeedItem objects have their ActsAsTaggableOn::Tag objects filtered via HubTagFilter, HubFeedTagFilter, and  HubFeedItemTagFilter objects.
#
# A Hub has one more more owners, and owners have the ability to manage HubFeed, RepublishedFeed, and many other objects.
#
# If a Hub has a tag_prefix defined, all tags on for FeedItems in this Hub will have it applied to them on output. So, if you use "oa." as a tag_prefix, all FeedItem tags will be prefixed with "oa." when they are published via rss, atom, xml, or json.
#
# The tag_prefix is smart enough not to duplicate itself if it already exists on a tag.
# 
# Most validations are contained in the ModelExtensions mixin.
#
class Hub < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  extend FriendlyId

  before_validation do
    auto_sanitize_html(:description)
  end

  DELEGATABLE_ROLES_HASH = {
    :editor => {:name => 'Editor',
      :description => 'Has edited metadata about this hub - does not confer any special privileges.',
      :objects_of_concern => lambda{|user,hub|
        return []
      }
    },
    :owner => {:name => 'Owner', 
      :description => 'Owns this hub, effectively able to do everything',
      :objects_of_concern => lambda{|user,hub|
        return []
      }
    }, 
    :creator => {
      :name => 'Creator', 
      :description => 'Created this hub - does not confer any special privileges',
      :objects_of_concern => lambda{|user,hub| 
        return []
      }
    }, 
    :bookmarker => {
      :name => 'Tagger', 
      :description => 'Can add bookmarks to this hub via the bookmarklet',
      :objects_of_concern => lambda{|user,hub|
        # Find all bookmark collections (and their hub feeds) in this hub owned by this user.
        bookmarking_feeds = user.my_bookmarking_bookmark_collections_in(hub.id)
        return [bookmarking_feeds, bookmarking_feeds.collect{|f| f.hub_feeds.reject{|hf| ! user.is?(:owner, hf)}}].flatten.compact
      }
    }, 
    :remixer => {
      :name => 'Feed Remixer', 
      :description => 'Can remix items in this hub into new remixed feeds',
      :objects_of_concern => lambda{|user,hub|
        #Find all republished_feeds in this hub owned by this user.
        return user.my_objects_in(RepublishedFeed, hub)
      }
    },
    :hub_tag_filterer => {
      :name => 'Hub-wide Tag Filter Manager', 
      :description => 'Can manage hub-wide tag filters in this hub',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_tag_filters in this hub owned by this user.
        return user.my_objects_in(HubTagFilter, hub)
      }
    },
    :hub_feed_tag_filterer => {
      :name => 'Feed-wide Tag Filter Manager', 
      :description => 'Can manage feed-level tag filters in this hub',
      :objects_of_concern => lambda{|user,hub|
        return user.my_objects_in(HubFeedTagFilter, hub)
      }
    },
    :hub_feed_item_tag_filterer => {
      :name => 'Feed Item Tag Filter Manager', 
      :description => 'Can manage item-level tag filters in this hub',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_feed_item_tag_filters in this hub owned by this user.
        return user.my_objects_in(HubFeedItemTagFilter, hub)
      }
    },
    :inputter => {
      :name => 'Input Feed Manager', 
      :description => 'Can manage input feeds',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_feeds that aren't bookmarking collections in this hub owned by this user.
        hub_feeds_of_concern = user.my_objects_in(HubFeed, hub)
        return hub_feeds_of_concern.reject{|hf| hf.feed.is_bookmarking_feed? == true}
      }
    }
  }
  
  DELEGATABLE_ROLES_FOR_FORMS = DELEGATABLE_ROLES_HASH.keys.reject{|r| [:creator,:editor].include?(r) }.collect{|r| [r, DELEGATABLE_ROLES_HASH[r][:name]]}

  DELEGATABLE_ROLES = DELEGATABLE_ROLES_HASH.keys.reject{|r| r == :creator}

  attr_accessible :title, :description, :tag_prefix, :nickname
  acts_as_authorization_object

  friendly_id :nickname, :use => [:slugged, :history]

  after_validation :move_friendly_id_error_to_nickname
  before_save :clean_slug

  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  has_many :hub_feeds, :dependent => :destroy
  has_many :hub_tag_filters, :dependent => :destroy, :order => 'created_at desc'
  has_many :republished_feeds, :dependent => :destroy, :order => 'created_at desc'
  has_many :feeds, :through => :hub_feeds

  api_accessible :default do |t|
    t.add :id
    t.add :title
    t.add :description
    t.add :created_at
    t.add :updated_at
  end
  
  def clean_slug
    # work around FriendlyId bug that generates slugs for empty nicknames
    self.slug = nil if nickname.blank?
    true
  end

  def move_friendly_id_error_to_nickname
    errors.add :nickname, *errors.delete(:friendly_id) if errors[:friendly_id].present?
  end

  def should_generate_new_friendly_id?
    !new_record? && nickname_changed?
  end   

  def self.top_new_hubs
    self.order('created_at DESC').limit(3)
  end

  def display_title
    title
  end

  def self.title
    'Hub'
  end

  alias :to_s :display_title

  # Used as the key to track the tag facet for this Hub's tags in a FeedItem.
  def tagging_key
    "hub_#{self.id}".to_sym
  end

end
