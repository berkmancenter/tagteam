class HubUserNotification < ApplicationRecord
  belongs_to :hub
  belongs_to :user
end
