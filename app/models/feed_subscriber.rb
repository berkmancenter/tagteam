class FeedSubscriber < ApplicationRecord
  validates :route, uniqueness: { scope: [:ip, :user_agent] }

  def self.count_for(route)
    FeedSubscriber.where(route: route).count
  end
end
