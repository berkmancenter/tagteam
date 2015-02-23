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
        link_to(
          raw(fa_icon('question-circle')),
          documentation_path(doc_object),
          class: 'doc-control dialog-show',
          title: doc_object.title
        )
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

  def insert_social_links(url, options = {})
    options.merge!({ rel: 'nofollow', target: '_blank', class: 'share_icon twitter'})
    output = []
    Tagteam::Application.config.social_links.each do|social_network|
      output << send("#{social_network}_share_link", url, options)
    end
    "<li>#{output.join('</li><li>')}</li>"
  end

  def twitter_share_link(url, options = {})
    link_to "https://twitter.com/intent/tweet?url=#{CGI.escape(url)}", options do
      fa_icon 'twitter', text: 'Share on Twitter'
    end
  end

  def facebook_share_link(url, options = {})
    link_to "https://www.facebook.com/sharer.php?u=#{CGI.escape(url)}", options do
      fa_icon 'facebook-square', text: 'Share on Facebook'
    end
  end

  def google_plus_share_link(url,options = {})
    link_to "https://plus.google.com/share?url=#{CGI.escape(url)}", options do
      fa_icon 'google-plus', text: 'Share on Google+'
    end
  end

  def use_breadcrumbs?
    blacklist = [['hubs', 'home'], ['hubs', 'new']]
    !(blacklist.include? [controller_name, action_name])
  end

  def show_liblab?
    whitelist = [['hubs', 'index']]
    whitelist.include? [controller_name, action_name]
  end
end
