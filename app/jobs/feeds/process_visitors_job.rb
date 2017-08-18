# frozen_string_literal: true

module Feeds
  # Save visits to feeds
  class ProcessVisitorsJob < ApplicationJob
    queue_as :subscribers

    def perform
      create_subscribers(new_subscribers)
      remove_inactive_subscribers
    end

    private

    def new_subscribers
      FeedVisitor
        .select(:route, :ip, :user_agent)
        .joins('LEFT JOIN feed_subscribers ON '\
        'feed_visitors.route = feed_subscribers.route AND '\
        'feed_visitors.ip = feed_subscribers.ip AND '\
        'feed_visitors.user_agent = feed_subscribers.user_agent')
        .group(:route, :ip, :user_agent)
        .where('feed_subscribers.id IS NULL')
    end

    def create_subscribers(new_subscribers)
      new_subscribers.each do |new_subscriber|
        FeedSubscriber.create!(
          route: new_subscriber.route,
          ip: new_subscriber.ip,
          user_agent: new_subscriber.user_agent
        )
      end
    end

    def remove_inactive_subscribers
      FeedSubscriber
        .joins('LEFT JOIN feed_visitors ON '\
        'feed_subscribers.route = feed_visitors.route AND '\
        'feed_subscribers.ip = feed_visitors.ip AND '\
        'feed_subscribers.user_agent = feed_visitors.user_agent')
        .where('feed_visitors.id IS NULL')
        .delete_all
    end
  end
end
