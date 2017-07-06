# frozen_string_literal: true

module Feeds
  # Remove outdated FeedVisitor records to keep subscriber statistics current
  class ExpireFeedVisitorsJob < ApplicationJob
    queue_as :subscribers

    def perform
      FeedVisitor.where('created_at < ?', 7.days.ago).delete_all
    end
  end
end
