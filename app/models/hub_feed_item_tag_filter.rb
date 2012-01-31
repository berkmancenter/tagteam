class HubFeedItemTagFilter < ActiveRecord::Base
  acts_as_list

  belongs_to :hub
  belongs_to :feed_item
  belongs_to :filter, :polymorphic => true
  attr_accessible :filter_type, :filter_id
end
