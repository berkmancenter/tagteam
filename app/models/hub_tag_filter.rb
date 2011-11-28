class HubTagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :filter, :as => :filterable
  acts_as_list

end
