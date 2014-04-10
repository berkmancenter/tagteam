class TagCountUpdater
  @queue = :renderer
  @logger = ActiveSupport::TaggedLogging.new(Logger.new("log/tag_count_updater.log"))
  def self.display_name
    'Updating tag counts'
  end

  def self.perform(hubs = Hub.all)
    hubs.each do |hub|
      @logger.info("#{Time.now.inspect}: Processing Hub##{hub.id} #{hub.title}")
      begin 
        hub.update_all_tag_count
        @logger.info("#{Time.now.inspect} Processing Hub##{hub.id} completed.")
      rescue => ex
        @logger.info("#{Time.now.inspect} Processing Hub##{hub.id} incompleted.")
        @logger.info(ex.message)
        @logger.info(ex.backtrace)
      end
    end
  end
end
