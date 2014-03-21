class TagCountUpdater
  @queue = :renderer

  def self.display_name
    'Updating tag counts'
  end

  def self.perform(hubs)
    hubs.each do |hub|
      hub.update_all_tag_count
    end
  end
end
