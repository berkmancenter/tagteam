class HubTagFilter < ActiveRecord::Base
  acts_as_list

  belongs_to :hub
  belongs_to :filter, :polymorphic => true, :dependent => :destroy
  attr_accessible :filter_type, :filter_id
  after_save :update_filtered_items
  before_destroy :update_filtered_items

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
