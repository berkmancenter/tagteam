# frozen_string_literal: true
require 'find'
class ExpireFileCache
  include Sidekiq::Worker
  sidekiq_options queue: :file_cache

  def self.display_name
    'Expiring cache entries'
  end

  def perform
    return if other_expirers_running?
    # A no-op unless we're using a file cache store.
    # Also, Marshal is pretty damned fast.
    if Rails.cache.class == ActiveSupport::Cache::FileStore
      Find.find(Rails.cache.cache_path) do |path|
        if FileTest.file?(path)
          c = Marshal.load(File.read(path))
          File.unlink(path) if c.expired?
        end
      end
    end
  end

  def other_expirers_running?
    workers = Sidekiq::Workers.new
    workers.any? do |_process_id, _thread_id, work|
      work['payload']['jid'] != jid && work['queue'] == 'file_cache'
    end
  end
end
