class HubTagDescription < ApplicationRecord
  validates_presence_of :hub_id, :tag_id
end
