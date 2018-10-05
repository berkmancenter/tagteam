# frozen_string_literal: true

module HubsHelper
  include Recaptcha::ClientHelper

  def limit_html(html, limit)
    require 'nokogiri'
    html = html[0..limit]
    Nokogiri::HTML.fragment(html).to_html
  end

  def sortable_link(name, sort, order, path = 'hubs_path', options = {})
    # Flip order only when has sort == name
    display_name = name.capitalize.to_s
    display_name += '?' if %w[locked confirmed].include?(name)
    display_order = order
    if name == sort
      order = order == 'desc' ? 'asc' : 'desc'
    end
    options.merge!({order: order, sort: name})

    link_to method(path).call(options),
            class: sort == name ? 'active text-primary' : '' do
      raw "#{display_name} #{fa_icon('caret-' + (display_order == 'desc' ? 'down' : 'up'))}"
    end
  end

  def items_feed_titles(item, hub)
    item.feeds.where(id: hub.feeds.pluck(:id)).map(&:title).join(', ')
  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  def valid_email?(email)
    /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/.match(email)
  end
end
