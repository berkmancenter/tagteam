class HubFeedTagFilter < ActiveRecord::Base
  acts_as_list

  belongs_to :hub_feed
  has_one :hub, :through => :hub_feed
  belongs_to :filter, :polymorphic => true
  attr_accessible :filter_type, :filter_id
  after_save :update_filtered_items
  before_destroy :update_filtered_items
  before_validation :validate_filter_uniqueness

  def validate_filter_uniqueness
    # So it makes no sense to allow a tag to be filtered multiple times at this level - 
    # so disallow it. This means we need to look up the stack to see what tag we're filtering on .
    filters_with_this_tag = self.class.where(:hub_feed_id => self.hub_feed_id).includes(:filter).collect{|hftf| hftf.filter.tag_id == self.filter.tag_id}.flatten.uniq
    
    if filters_with_this_tag.include?(true)
      self.errors.add(:base, 'This tag is already being filtered for this feed.')
    end
  end


  def update_filtered_items
    if self.filter.class == AddTagFilter
      #act on all items
      Resque.enqueue(HubFeedFeedItemTagRenderer, self.hub_feed.id)
    else
      # act only on the items tagged with a specific tag.
      Resque.enqueue(HubFeedFeedItemTagRenderer, self.hub_feed.id, self.filter.tag_id)
    end
  end

end
