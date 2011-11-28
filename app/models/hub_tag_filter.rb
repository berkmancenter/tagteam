class HubTagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :filter, :polymorphic => true
  acts_as_list

end
