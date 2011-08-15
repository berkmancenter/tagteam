class RepublishedFeed < ActiveRecord::Base

  include ModelExtensions

  SORTS = ['date_published', 'title']
  MIXING_STRATEGIES = ['interlaced','date']

  belongs_to :hub
  has_many :input_sources, :dependent => :destroy, :order => :position 

  def resolved_items
    #here's where we'll iterate through input_sources, add or subtract them and come to a final list of items.
  end

end
