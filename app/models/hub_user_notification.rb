# frozen_string_literal: true

# Stores per-hub notification settings for users
class HubUserNotification < ApplicationRecord
  belongs_to :hub, optional: true
  belongs_to :user, optional: true

  validates :hub, presence: true
  validates :user, presence: true, uniqueness: { scope: :hub_id }
end
