class HubFeedItemTagFilter < ActiveRecord::Base
  acts_as_list

  belongs_to :hub
  belongs_to :feed_item
  belongs_to :filter, :polymorphic => true
  attr_accessible :filter_type, :filter_id
  after_save :update_feed_item_tags
  before_destroy :update_feed_item_tags

  before_validation :validate_filter_uniqueness

  def validate_filter_uniqueness
    # So it makes no sense to allow a tag to be filtered multiple times at this level - 
    # so disallow it. This means we need to look up the stack to see what tag we're filtering on .
    filters_with_this_tag = self.class.where(:hub_id => self.hub_id, :feed_item_id => self.feed_item_id).includes(:filter).collect{|hfitf| hfitf.filter.tag_id == self.filter.tag_id}.flatten.uniq
    
    if filters_with_this_tag.include?(true)
      self.errors.add(:base, 'This tag is already being filtered for this feed item.')
    end
  end

  def update_feed_item_tags
    Resque.enqueue(FeedItemTagRenderer, self.feed_item_id)
  end

end
