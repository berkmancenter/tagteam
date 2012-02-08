class HubTagFilter < ActiveRecord::Base
  acts_as_list

  belongs_to :hub
  belongs_to :filter, :polymorphic => true, :dependent => :destroy
  attr_accessible :filter_type, :filter_id
  after_save :update_filtered_items
  before_destroy :update_filtered_items
  before_validation :validate_filter_uniqueness

  def validate_filter_uniqueness
    # So it makes no sense to allow a tag to be filtered multiple times at this level - 
    # so disallow it. This means we need to look up the stack to see what tag we're filtering on .
    filters_with_this_tag = self.class.where(:hub_id => self.hub_id).includes(:filter).collect{|htf| htf.filter.tag_id == self.filter.tag_id}.flatten.uniq
    
    if filters_with_this_tag.include?(true)
      self.errors.add(:base, 'This tag is already being filtered for this hub.')
    end
  end

  def update_filtered_items
    if self.filter.class == AddTagFilter
      #act on all items
      Resque.enqueue(HubWideFeedItemTagRenderer, self.hub.id)
    else
      # act only on the items tagged with a specific tag.
      Resque.enqueue(HubWideFeedItemTagRenderer, self.hub.id, self.filter.tag_id)
    end
  end

end
