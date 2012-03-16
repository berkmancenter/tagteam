require 'find'
class ExpireFileCache
  @queue = :file_cache

  def self.perform
    # A no-op unless we're using a file cache store.
    if Rails.cache.class == ActiveSupport::Cache::FileStore
      Find.find(Rails.cache.cache_path) do |path|
        if FileTest.file?(path)
          c = Marshal.load(File.read(path))
          if c.expired?
            File.unlink(path)
          end
        end
      end
    end
  end

end
