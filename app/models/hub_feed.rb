class HubFeed < ActiveRecord::Base
  include ModelExtensions

  belongs_to :hub
  belongs_to :feed

  validates_uniqueness_of :feed_id, :scope => :hub_id

  def display_title
    (self.title.blank?) ? self.feed.title : self.title
  end
  
  def display_description
    (self.description.blank?) ? self.feed.description : self.description
  end

end
