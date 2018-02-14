# frozen_string_literal: true

class RecalcAllItems
  include Sidekiq::Worker
  sidekiq_options queue: :renderer

  def self.display_name
    'Updating all tags for an entire hub'
  end

  def perform(hub_id)
    puts "Reapplying tag filters for hub #{hub_id}"
    hub = Hub.find(hub_id)
    return if hub.all_tag_filters.count == 0
    bar = ProgressBar.new(hub.all_tag_filters.count)

    hub.all_tag_filters.each do |filter|
      filter.apply
      bar.increment!
    end
  end
end
