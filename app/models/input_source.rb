class InputSource < ActiveRecord::Base
  include ModelExtensions

  validates_uniqueness_of :item_source_type, :scope => [:item_source_id, :effect, :republished_feed_id]

  EFFECTS = ['add','remove']

  belongs_to :republished_feed
  belongs_to :item_source, :polymorphic => true

  acts_as_list :scope => :republished_feed_id
  validates_inclusion_of :effect, :in => EFFECTS

  attr_accessible :item_source, :republished_feed_id, :item_source_id, :item_source_type, :effect, :position, :limit
  attr_accessor :search_in

  def search_in
    'Feed'
  end
  
end
