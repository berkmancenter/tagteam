class UpdateFeeds
  require 'sidekiq/api'
  include Sidekiq::Worker
  sidekiq_options queue: :updater, retry: false

  def self.display_name
    "Looking for new or changed feed items"
  end

  def perform
    return if other_updaters_running?
    feeds = HubFeed.need_updating
    feeds.each do|hf|
      hf.feed.update_feed
    end
  end

  def other_updaters_running?
    workers = Sidekiq::Workers.new
    workers.any?{ |process_id, thread_id, work| work['queue'] == 'updater' }
  end
end
