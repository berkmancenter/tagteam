class InputSource < ActiveRecord::Base
  include ModelExtensions

  validates_uniqueness_of :item_source_type, :scope => [:item_source_id, :effect, :republished_feed_id]

  EFFECTS = ['add','remove']

  belongs_to :republished_feed
  belongs_to :item_source, :polymorphic => true

  acts_as_list :scope => :republished_feed_id
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end
  validates_inclusion_of :effect, :in => EFFECTS

  attr_accessible :item_source, :republished_feed_id, :item_source_id, :item_source_type, :effect, :position, :limit, :search_in
  attr_accessor :search_in

  api_accessible :default do |t|
    t.add :id
    t.add :republished_feed_id
    t.add :item_source_type
    t.add :item_source_id
    t.add :effect
    t.add :position
  end

  def search_in
    'Feed'
  end
  
end
