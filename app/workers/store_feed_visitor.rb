# frozen_string_literal: true
class StoreFeedVisitor
  include Sidekiq::Worker
  sidekiq_options queue: :subscribers

  def self.display_name
    'Storing information about a feed visitor'
  end

  def perform(route, feed_type, user_ip, user_agent)
    browser = Browser.new(user_agent, {})

    return unless %w(rss atom).include? feed_type
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
