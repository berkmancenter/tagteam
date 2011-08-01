class HubFeed < ActiveRecord::Base
  include ModelExtensions

  belongs_to :hub
  belongs_to :feed

  def display_title
    (self.title.blank?) ? self.feed.title : self.title
  end
  
  def display_description
    (self.description.blank?) ? self.feed.description : self.description
  end

end
