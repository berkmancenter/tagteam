class InputSource < ActiveRecord::Base
  include ModelExtensions

  EFFECTS = ['add','remove']

  belongs_to :republished_feed
  belongs_to :item_source, :polymorphic => true

  acts_as_list :scope => :republished_feed_id
  validates_inclusion_of :effect, :in => EFFECTS
  validates_presence_of :item_source_id, :item_source_type

  attr_accessible :item_source, :item_source_id, :item_source_type, :effect, :position, :limit
  
end
