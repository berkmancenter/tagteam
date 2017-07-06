# frozen_string_literal: true

module Feeds
  # Create a new FeedVisitor record for a non-bot visit
  class StoreFeedVisitorJob < ApplicationJob
    queue_as :subscribers

    def perform(route, feed_type, ip, user_agent)
      browser = Browser.new(user_agent, {})

      return unless %w[rss atom json].include? feed_type
      return if browser.bot?

      FeedVisitor.create!(route: route, ip: ip, user_agent: user_agent)
    end
  end
end
