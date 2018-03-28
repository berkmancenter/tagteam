# frozen_string_literal: true

module FeedItems
  # Update an existing feed item
  class Update < ActiveInteraction::Base
    string :description
    object :feed_item
    object :hub
    string :title
    string :url
    date :date_published
    object :user

    def execute
      changes = detect_changes(feed_item, description, title, url, )

      if feed_item.update(description: description, title: title, url: url)
        FeedItems::SendChangeNotificationJob.perform_later(
          changes: changes,
          current_user: user,
          feed_item: feed_item,
          hub: hub
        )
      else
        errors.merge!(feed_item.errors)
      end

      feed_item
    end

    private

    def detect_changes(feed_item, description, title, url)
      changes = {}

      changes[:description] = [strip_tags(feed_item.description), strip_tags(description)] if feed_item.description != description
      changes[:title] = [feed_item.title, title] if feed_item.title != title
      changes[:url] = [feed_item.url, url] if feed_item.url != url

      changes[:date_published] = [feed_item.date_published.to_s, @date_published.to_s] if @date_published != @feed_item.date_published.to_date

      changes
    end

    def strip_tags(string)
      ActionController::Base.helpers.strip_tags(string)
    end
  end
end
