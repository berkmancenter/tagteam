# frozen_string_literal: true

module Feeds
  # Save visits to feeds
  class ProcessVisitorsJob < ApplicationJob
    queue_as :subscribers

    def perform
      # add new subscribers
      new_subscribers = FeedVisitor
                        .select(:route, :ip, :user_agent)
                        .joins('LEFT JOIN feed_subscribers ON '\
                        'feed_visitors.route = feed_subscribers.route AND '\
                        'feed_visitors.ip = feed_subscribers.ip AND '\
                        'feed_visitors.user_agent = feed_subscribers.user_agent')
                        .group(:route, :ip, :user_agent)
                        .having('count(*) > ?', 1)
                        .where('feed_subscribers.id IS NULL')

      new_subscribers.each do |new_subscriber|
        feed_subscriber = FeedSubscriber.new

        feed_subscriber.attributes = {
          route: new_subscriber.route,
          ip: new_subscriber.ip,
          user_agent: new_subscriber.user_agent
        }

        feed_subscriber.save
      end

      # remove retired subscribers
      retired_subscribers = FeedSubscriber
                            .joins('LEFT JOIN feed_visitors ON '\
                            'feed_subscribers.route = feed_visitors.route AND '\
                            'feed_subscribers.ip = feed_visitors.ip AND '\
                            'feed_subscribers.user_agent = feed_visitors.user_agent')
                            .where('feed_visitors.id IS NULL')

      retired_subscribers.delete_all
    end
  end
end
