class RepublishedFeed < ActiveRecord::Base

  include AuthUtilities
  include ModelExtensions

  acts_as_authorization_object
  SORTS = ['date_published', 'title']
  SORTS_FOR_SELECT = [['Date Published','date_published' ],['Title', 'title']]
  MIXING_STRATEGIES = ['interlaced','date']
  MIXING_STRATEGIES_FOR_SELECT = [['Interlaced','interlaced'],['Date','date']]

  belongs_to :hub
  has_many :input_sources, :dependent => :destroy, :order => :position 

  attr_accessible :title, :hub_id, :description, :default_sort, :mixing_strategy, :limit

  def items
    #here's where we'll iterate through input_sources, add or subtract them and come to a final list of items.
    # This is currently VERY inefficient and will not scale well when there are many input sources and/or feed items
    items = []
    self.input_sources.each do|input_source|
      if input_source.effect == 'add'
        items << input_source.item_source.items(self.hub)
      end
    end
    output_items = items.flatten.uniq.compact

    self.input_sources.each do|input_source|
      if input_source.effect == 'remove'
        output_items = output_items - input_source.item_source.items
      end
    end

    output_items = output_items.sort_by{|i| (self.default_sort == 'date_published') ? i.date_published : i.title}
    if self.default_sort == 'date_published'
      output_items.reverse!
    end
    # DANGER, WILL ROBINSON! Inefficient. 
    output_items[0..self.limit]
  end

  def to_s
    "#{title}"
  end

end
