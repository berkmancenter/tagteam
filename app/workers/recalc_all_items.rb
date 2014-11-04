class RecalcAllItems
  include Sidekiq::Worker
  sidekiq_options :queue => :renderer

  def self.display_name
    "Updating all tags for an entire hub"
  end

  def perform(hub_id)
    hub = Hub.find(hub_id)

    HubFeed.all(:conditions => {:hub_id => hub_id}).each do |hf|
      hf.feed_items.each do|fi|
        fi.render_filtered_tags_for_hub(hub)
        fi.save
      end
    end

  end

end
