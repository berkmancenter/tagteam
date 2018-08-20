class HubApprovedTag < ApplicationRecord
  belongs_to :hub, optional: true
end
