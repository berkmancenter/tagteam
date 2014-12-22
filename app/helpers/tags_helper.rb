module TagsHelper
  def tag_cloud(tags, classes)
    #logger.info(tags.inspect)
    return [] if tags.empty?

    max_count = tags.sort_by(&:count).last.count.to_f

    tags.each do |tag|
      index = ((tag.count / max_count) * (classes.size - 1))
      yield tag, classes[index.nan? ? 0 : index.round]
    end
  end

  def tag_display(tag, options = {})
    options.merge!({
      :class => ['tag', options[:class]].compact.join(' '),
      "data-tag-id" => tag.id,
      "data-tag-name" => tag.name
    })

    hub_id = nil
    if ! options[:hub].blank?
      options.merge!({"data-hub-id" => options[:hub].id})
      hub_id = options[:hub].id
      options.delete(:hub)

    end

    if ! options[:hub_feed].blank?
      options.merge!({"data-hub-feed-id" => options[:hub_feed].id})
      options.delete(:hub_feed)
    end

    if ! options[:hub_feed_item].blank?
      options.merge!({"data-hub-feed-item-id" => options[:hub_feed_item].id})
      options.delete(:hub_feed_item)
    end

    if ! options[:show_count].blank?
      tag_count = options[:use_count] ? tag.count : tag.count_by_hub(Hub.find(hub_id))
      options.merge!({"data-tag-frequency" => tag_count})
      options.delete(:show_count)
    end

    link_to(tag.name, hub_tag_show_path(hub_id, u(tag.name)), options)
  end

end
