# frozen_string_literal: true

module HubsHelper
  def limit_html(html, limit)
    require 'nokogiri'
    html = html[0..limit]
    Nokogiri::HTML.fragment(html).to_html
  end

  def sortable_link(name, sort, order, path = 'hubs_path')
    has_name_and_asc = ((sort == name) && (order == 'asc'))
    link_to method(path).call(order: (has_name_and_asc ? 'desc' : 'asc'), sort: name),
            class: sort == name ? 'active text-primary' : '' do
      raw "#{name.capitalize} #{fa_icon('caret-' + (has_name_and_asc || sort != name ? 'down' : 'up'))}"
    end
  end

  def items_feed_titles(item, hub)
    item.feeds.where(id: hub.feeds.pluck(:id)).map(&:title).join(', ')
  end
end
