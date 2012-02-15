class RecalcAllItems
  @queue = :all_items

  def self.perform(hub_id)
    hub = Hub.find(hub_id)

    HubFeed.all(:conditions => {:hub_id => hub_id}).each do |hf|
      hf.feed_items.each do|fi|
        fi.render_filtered_tags_for_hub(hub)
        fi.save
      end
    end

  end

end
