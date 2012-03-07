module ApplicationHelper

  def documentation(match_key, title = match_key)
    doc_object = Documentation.find_or_initialize_by_match_key(match_key)
    if doc_object.new_record?
      doc_object.title = title || match_key
      doc_object.save
    end
    if ! doc_object.description.blank? || (current_user && current_user.has_role?(:superadmin))
      link_to(raw('<span class="inline ui-silk ui-silk-information"></span> Help!'), documentation_path(doc_object), :class => 'documentation_control dialog-show')
    end
  end

  def page_title
    if breadcrumbs.items.length == 0
      'TagTeam'
    else
      breadcrumbs.items.collect{|i| i[0]}.reject{|i| i == 'Home'}.reverse.join(' :: ') + ' :: TagTeam'
    end
  end

  def tag_display(tag, options = {})
    options.merge!({:class => ['tag', options[:class]].compact.join(' '), :data_tag_id => tag.id})

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

    if ! options[:hub_feed_item].blank?
      options.merge!({:data_hub_feed_item_id => options[:hub_feed_item].id})
      options.delete(:hub_feed_item)
    end

    link_to(tag.name, hub_tag_show_path(hub_id,u(tag.name)), options) 
  end

end
