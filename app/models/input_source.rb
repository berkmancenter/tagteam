# An InputSource adds or removes FeedItem objects from a RepublishedFeed. It has a polymorphic relationship to an ItemSource (currently Feeds, Tags, and an individual FeedItem). It will be very easy to add additional ItemSource objects - all they have to do is respond to the "items" method call with an array of FeedItem objects.
#
# In the future we may allow RepublishedFeed objects themselves to serve as ItemSources, and ideally the search engine would allow searches to be InputSources.
# 
# If I liked single table inheritance, we'd probably have InputSource and RemovalSource classes keyed on the "effect" attribute.
# 
# Most validations are contained in the ModelExtensions mixin.
#
class InputSource < ActiveRecord::Base
  include ModelExtensions

  validates_uniqueness_of :item_source_type, :scope => [:item_source_id, :effect, :republished_feed_id]

  EFFECTS = ['add','remove']

  belongs_to :republished_feed
  belongs_to :item_source, :polymorphic => true

  acts_as_list :scope => :republished_feed_id
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end
  validates_inclusion_of :effect, :in => EFFECTS

  attr_accessible :item_source, :republished_feed_id, :item_source_id, :item_source_type, :effect, :position, :limit, :search_in
  attr_accessor :search_in

  api_accessible :default do |t|
    t.add :id
    t.add :republished_feed_id
    t.add :item_source_type
    t.add :item_source_id
    t.add :effect
    t.add :position
  end

  # Get rid of this when removing the input source editing.
  def search_in
    'Feed'
  end
  
end
