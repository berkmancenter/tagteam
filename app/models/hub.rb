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

  before_validation do
    auto_sanitize_html(:description)
  end

  DELEGATABLE_ROLES_HASH = {
    :owner => {:name => 'Owner', 
      :description => 'Owns this hub, effectively able to do everything',
      :objects_of_concern => lambda{|user,hub|
        []
      }
    }, 
    :creator => {
      :name => 'Creator', 
      :description => 'Created this hub - does not confer any special privileges',
      :objects_of_concern => lambda{|user,hub| 
        []
      }
    }, 
    :bookmarker => {
      :name => 'Tagger', 
      :description => 'Can add bookmarks to this hub via the bookmarklet'
      :objects_of_concern => lambda{|user,hub|
        # Find all bookmark collections in this hub owned by this user.


      }
    }, 
    :remixer => {
      :name => 'Feed Remixer', 
      :description => 'Can remix items in this hub into new remixed feeds',
      :objects_of_concern => lambda{|user,hub|
        #Find all republished_feeds in this hub owned by this user.
      }
    },
    :hub_tag_filterer => {
      :name => 'Hub-wide Tag Filter Manager', 
      :description => 'Can manage hub-wide tag filters in this hub',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_tag_filters in this hub owned by this user.
      }
    },
    :hub_feed_tag_filterer => {
      :name => 'Feed-wide Tag Filter Manager', 
      :description => 'Can manage feed-level tag filters in this hub',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_feed_tag_filters in this hub owned by this user.
      }
    },
    :hub_feed_item_tag_filterer => {
      :name => 'Feed Item Tag Filter Manager', 
      :description => 'Can manage item-level tag filters in this hub',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_feed_item_tag_filters in this hub owned by this user.
      }
    },
    :inputter => {
      :name => 'Input Feed Manager', 
      :description => 'Can manage input feeds',
      :objects_of_concern => lambda{|user,hub|
        #Find all hub_feeds in this hub owned by this user.
      }
    }
  }
  
  DELEGATABLE_ROLES_FOR_FORMS = DELEGATABLE_ROLES_HASH.keys.reject{|r| r == :creator}.collect{|r| [r, DELEGATABLE_ROLES_HASH[r][:name]]}

  DELEGATABLE_ROLES = DELEGATABLE_ROLES_HASH.keys.reject{|r| r == :creator}

  attr_accessible :title, :description, :tag_prefix
  acts_as_authorization_object

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

  def display_title
    self.title
  end

  alias :to_s :display_title

  # Used as the key to track the tag facet for this Hub's tags in a FeedItem.
  def tagging_key
    "hub_#{self.id}".to_sym
  end

end
