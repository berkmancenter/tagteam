# frozen_string_literal: true
require 'find'
class ClearFeedVisitors
  include Sidekiq::Worker
  sidekiq_options queue: :file_cache

  def self.display_name
    'Clearing feed visitors data'
  end

  def perform
    FeedVisitor.where('created_at < ?', 4.days.ago).delete_all
  end
end
