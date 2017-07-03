# frozen_string_literal: true

module Feeds
  # Create a new FeedVisitor record for a non-bot visit
  class StoreFeedVisitorJob < ApplicationJob
    queue_as :subscribers

    def perform(route, feed_type, user_ip, user_agent)
      browser = Browser.new(user_agent, {})

      return unless %w[rss atom].include? feed_type
      return if browser.bot?

      feed_visitor = FeedVisitor.new

      feed_visitor.attributes = {
        route: route,
        ip: user_ip,
        user_agent: user_agent
      }

      feed_visitor.save!
    end
  end
end
