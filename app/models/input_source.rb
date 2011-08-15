class InputSource < ActiveRecord::Base
  include ModelExtensions

  EFFECTS = ['add','remove']

  belongs_to :republished_feed
  belongs_to :item_source, :polymorphic => true

  acts_as_list :scope => :republished_feed_id
  validates_inclusion_of :effect, :in => EFFECTS
  
end
