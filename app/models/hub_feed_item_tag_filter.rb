class HubFeedItemTagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :hub_feed_item
  belongs_to :filter, :polymorphic => true
  acts_as_list
end
