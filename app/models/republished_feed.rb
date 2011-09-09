class RepublishedFeed < ActiveRecord::Base

  include ModelExtensions

  SORTS = ['date_published', 'title']
  SORTS_FOR_SELECT = [['Date Published','date_published' ],['Title', 'title']]
  MIXING_STRATEGIES = ['interlaced','date']
  MIXING_STRATEGIES_FOR_SELECT = [['Interlaced','interlaced'],['Date','date']]

  belongs_to :hub
  has_many :input_sources, :dependent => :destroy, :order => :position 

  attr_accessible :title, :hub_id, :description, :default_sort, :mixing_strategy

  def items
    #here's where we'll iterate through input_sources, add or subtract them and come to a final list of items.
    items = []
    self.input_sources.each do|input_source|
      if input_source.effect == 'add'
        items << input_source.item_source.items
      elsif input_source.effect == 'remove'
        items = items - input_source.item_source.items
      end
    end
    items.flatten.uniq.compact
  end

end
