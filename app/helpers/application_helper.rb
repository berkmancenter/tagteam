module ApplicationHelper

  def protocol_resolver
    if Rails.env == 'production' && Tagteam::Application.config.ssl_for_user_accounts == true
      'https'
    else
      'http'
    end
  end

  def documentation(match_key, title = match_key, label_type = 'help')
    doc_object = Documentation.find_or_initialize_by_match_key(match_key)
    if doc_object.new_record?
      doc_object.title = title || match_key
      doc_object.save
    end
    if ! doc_object.description.blank? || (current_user && current_user.is?([:superadmin,:documentation_admin]))
      if label_type == 'help'
        link_to(raw('<span class="inline ui-silk ui-silk-information"></span> Help!'), documentation_path(doc_object), :class => 'documentation_control dialog-show')
      end
    end
  end

  def page_title
    if breadcrumbs.items.length == 1
      'TagTeam'
    else
     "TagTeam :: #{breadcrumbs.items.collect{|i| i[0]}.reject{|i| i == 'Home'}.reverse.flatten.compact.join(' - ')}"
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

  def insert_social_links(url, options = {})
    options.merge!({:rel => 'nofollow', :target => '_blank', :class => 'share_icon twitter'})
    output = []
    Tagteam::Application.config.social_links.each do|social_network|
      output << send("#{social_network}_share_link", url, options)
    end
    output.join('<br/>')
  end

  def twitter_share_link(url, options = {})
    link_to(raw(image_tag('twitter-icon.png') + ' Share on Twitter'), "https://twitter.com/intent/tweet?url=#{CGI.escape(url)}", options)
  end

  def facebook_share_link(url, options = {})
    link_to(raw(image_tag('facebook-icon.png') + ' Share on Facebook'), "https://www.facebook.com/sharer.php?u=#{CGI.escape(url)}", options)
  end

  def google_plus_share_link(url,options = {})
    link_to(raw(image_tag('google-plus-icon.png') + ' Share on Google+'), "https://plus.google.com/share?url=#{CGI.escape(url)}", options)
  end

end
