# A HubTagFilter is applied to all FeedItems in a Hub. It is applied first in the filter chain, and can be overridden by HubFeedTagFilters or HubFeedItemTagFilters as they are more specific than this one.
#
# This filter is a great way to clean up and remove spurious tags in your Hub. You can also add tags at this level, but it doesn't seem all that useful to apply a tag to everything you're aggregating.
#
class HubTagFilter < ActiveRecord::Base
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  belongs_to :hub
  belongs_to :filter, :polymorphic => true, :dependent => :destroy
  attr_accessible :filter_type, :filter_id
  after_save :update_filtered_items
  before_destroy :update_filtered_items
  before_validation :validate_filter_uniqueness

  api_accessible :default do |t|
    t.add :id
    t.add :filter_type
    t.add :filter
  end

  # It makes no sense to allow a tag to be filtered multiple times at this level - 
  # so disallow it. This means we need to look up the stack to see what tag we're filtering on .
  def validate_filter_uniqueness
    filters_with_this_tag = self.class.where(:hub_id => self.hub_id).includes(:filter).collect{|htf| htf.filter.tag_id == self.filter.tag_id}.flatten.uniq
    
    if filters_with_this_tag.include?(true)
      self.errors.add(:base, 'This tag is already being filtered for this hub.')
    end
  end

  # Update all FeedItems in this Hub. There is some intelligence built into this action in that we try to restrict to only those items that would be effected by this change, but it's expensive and especially so when a tag is added.
  def update_filtered_items
    if self.filter.class == AddTagFilter
      #act on all items
      Resque.enqueue(HubWideFeedItemTagRenderer, self.hub_id)
    else
      # act only on the items tagged with a specific tag.
      Resque.enqueue(HubWideFeedItemTagRenderer, self.hub_id, self.filter.tag_id)
    end
  end

end
