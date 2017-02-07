# frozen_string_literal: true
# An InputSource adds or removes FeedItem objects from a RepublishedFeed. It has a polymorphic relationship to an ItemSource (currently Feeds, Tags, and an individual FeedItem). It will be very easy to add additional ItemSource objects - all they have to do is respond to the "items" method call with an array of FeedItem objects.
#
# In the future we may allow RepublishedFeed objects themselves to serve as ItemSources, and ideally the search engine would allow searches to be InputSources.
#
# If I liked single table inheritance, we'd probably have InputSource and RemovalSource classes keyed on the "effect" attribute.
#
# Most validations are contained in the ModelExtensions mixin.
#
class InputSource < ActiveRecord::Base
  include AuthUtilities
  acts_as_authorization_object
  include ModelExtensions

  validates :item_source_type, uniqueness: { scope: [:item_source_id, :effect, :republished_feed_id] }

  EFFECTS = %w(add remove).freeze

  belongs_to :republished_feed
  belongs_to :item_source, polymorphic: true

  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end
  validates :effect, inclusion: { in: EFFECTS }
  accepts_nested_attributes_for :item_source
  attr_accessible :item_source, :item_source_attributes, :republished_feed, :republished_feed_id, :item_source_id, :item_source_type, :effect, :limit, :search_in
  attr_accessor :search_in

  api_accessible :default do |t|
    t.add :id
    t.add :republished_feed_id
    t.add :item_source_type
    t.add :item_source_id
    t.add :effect
  end

  delegate :to_s, to: :item_source

  # Get rid of this when removing the input source editing.
  def search_in
    'Feed'
  end

  def self.title
    'Remixed Feed Item Source'
  end

  def item_source_attributes=(attrs)
    self.item_source = attrs[:type].constantize.find_or_initialize_by(name: attrs[:name]) if attrs[:name]
  end
end
