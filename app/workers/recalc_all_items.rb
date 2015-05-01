class RecalcAllItems
  include Sidekiq::Worker
  sidekiq_options :queue => :renderer

  def self.display_name
    "Updating all tags for an entire hub"
  end

  def perform(hub_id)
    hub = Hub.find(hub_id)
    bar = ProgressBar.new(
      hub.hub_feeds.map{|hf| hf.feed_items.count}.sum,
      :bar, :percentage, :counter, :elapsed, :rate, :eta
    )

    hub.hub_feeds.each do |hf|
      hf.feed_items.find_each(batch_size: 200) do |fi|
        fi.render_filtered_tags_for_hub(hub)
        fi.save
        bar.increment!
      end
    end

  end

end
