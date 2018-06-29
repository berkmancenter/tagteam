# frozen_string_literal: true
module TagsHelper
  def tag_cloud(tags, classes)
    # logger.info(tags.inspect)
    return [] if tags.empty?

    max_count = tags.sort_by(&:count).last.count.to_f

    tags.each do |tag|
      index = ((tag.count / max_count) * (classes.size - 1))
      yield tag, classes[index.nan? ? 0 : index.round]
    end
  end

  def tag_display(tag, options = {})
    options.merge!(:class => ['tag', options[:class]].compact.join(' '),
                   'data-tag-id' => tag.id,
                   'data-tag-name' => tag.name)

    hub_id = nil
    unless options[:hub].blank?
      options['data-hub-id'] = options[:hub].id
      hub_id = options[:hub].id
      options.delete(:hub)

    end

    unless options[:hub_feed].blank?
      options['data-hub-feed-id'] = options[:hub_feed].id
      options.delete(:hub_feed)
    end

    unless options[:hub_feed_item].blank?
      options['data-hub-feed-item-id'] = options[:hub_feed_item].id
      options.delete(:hub_feed_item)
    end

    unless options[:show_count].blank?
      tag_count = options[:use_count] ? tag.count : tag.count_by_hub(Hub.find(hub_id))
      options['data-tag-frequency'] = tag_count
      options.delete(:show_count)
    end

    link_to(tag.name, hub_tag_show_path(hub_id, tag.name), options)
  end

  def hub_filter_possible?(type, _params, current_user)
    roles = [:owner]

    case type
    when :add
      roles << :hub_tag_adder
    when :delete
      roles << :hub_tag_deleter
    when :modify
      roles << :hub_tag_modifier
    when :supplement
      roles << :hub_tag_supplementer
    end

    (current_user.is?(roles, @hub) || current_user.superadmin?) && !@already_filtered_for_hub
  end

  def feed_filter_possible?(params, current_user)
    params[:hub_feed_id].to_i != 0 &&
      (current_user.is?(%i[owner hub_feed_tag_filterer], @hub) || current_user.superadmin?) &&
      !@already_filtered_for_hub_feed
  end

  def item_filter_possible?(params, current_user)
    params[:hub_feed_item_id].to_i != 0 &&
      (current_user.is?(%i[owner hub_feed_item_tag_filterer], @hub) || current_user.superadmin?) &&
      !@already_filtered_for_hub_feed_item
  end

  def link_to_tag_filter(text, type, context = {})
    options = {
      class: 'add_filter_control',
      data_type: "#{type.to_s.capitalize}TagFilter"
    }

    options[:data_id] = context[:tag].id if context[:tag]
    options[:data_hub_id] = context[:hub].id
    options[:tag_list] = context[:tag_list] if context[:tag_list]

    if context[:feed]
      path = hub_feed_tag_filters_path(context[:feed])
      add_class = 'hub_feed_tag_filter'
    elsif context[:hub] && context[:item]
      path = hub_feed_item_tag_filters_path(context[:hub], context[:item])
      add_class = 'hub_feed_item_tag_filter'
    elsif context[:hub]
      path = hub_tag_filters_path(context[:hub])
      add_class = 'hub_tag_filter'
    end

    options[:class] += ' ' + add_class

    link_to text, path, options
  end
end
