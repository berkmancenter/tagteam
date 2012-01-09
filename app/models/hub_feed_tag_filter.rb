class HubFeedTagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :hub_feed
  belongs_to :filter, :polymorphic => true
  acts_as_list
end
