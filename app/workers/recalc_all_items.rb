class RecalcAllItems
  include Sidekiq::Worker
  sidekiq_options :queue => :renderer

  def self.display_name
    "Updating all tags for an entire hub"
  end

  def perform(hub_id)
    hub = Hub.find(hub_id)
    bar = ProgressBar.new(
      hub.all_tag_filters.count,
      :bar, :percentage, :counter, :elapsed, :rate, :eta
    )

    hub.all_tag_filters.each do |filter|
      filter.apply
      bar.increment!
    end
  end
end
