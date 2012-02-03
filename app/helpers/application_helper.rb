module ApplicationHelper

  def tag_display(tag, options = {})
    options.merge!({:class => 'tag', :data_tag_id => tag.id})

    hub_id = nil
    if ! options[:hub].blank?
      options.merge!({:data_hub_id => options[:hub].id})
      hub_id = options[:hub].id
      options.delete(:hub)

    end

    if ! options[:hub_feed].blank?
      options.merge!({:data_hub_feed_id => options[:hub_feed].id})
      options.delete(:hub_feed)
    end

    if ! options[:feed_item].blank?
      options.merge!({:data_feed_item_id => options[:feed_item].id})
      options.delete(:feed_item)
    end

    link_to(tag.name, hub_tag_path(hub_id,tag), options) 
  end

end
