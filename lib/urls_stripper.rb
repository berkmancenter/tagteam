# Helps strip tracking codes etc. from urls
module UrlsStripper
  TRACKERS_BY_ROOT = {

    # Google's Urchin Tracking Module
    'utm_' => [
      'source',
      'medium',
      'term',
      'campaign',
      'content',
      'name',
      'cid',
      'reader',
      'viz_id',
      'pubreferrer',
      'swu'
    ],

    # Adobe Omniture SiteCatalyst
    'IC' => [
      'ID'
    ],

    # Adobe Omniture SiteCatalyst
    'ic' => [
      'id'
    ],

    # Hubspot
    '_hs' => [
      'enc',
      'mi'
    ],

    # Marketo
    'mkt_' => [
      'tok'
    ],

    # MailChimp
    # https://developer.mailchimp.com/documentation/mailchimp/guides/getting-started-with-ecommerce/
    'mc_' => [
      'cid',
      'eid'
    ],

    # Simple Reach
    'sr_' => [
      'share'
    ],

    # Vero
    'vero_' => [
      'conv',
      'id'
    ],

    # Non-prefixy and 1-offs
    '' => [
      # Google Click Identifier
      'gclid',
      # Unknown
      'ncid',
      # Unknown
      'nr_email_referer',
      # Generic-ish. Facebook, Product Hunt and others
      'ref',
      # Alibaba-family 'super position model' tracker:
      'spm'
    ]
  }.freeze

  TRACKER_REGEXES_BY_ROOT = {}
  TRACKERS_BY_ROOT.each_key do |key|
    TRACKER_REGEXES_BY_ROOT[key] = Regexp.new(
      '((^|&)' \
      + key \
      + '(' + TRACKERS_BY_ROOT[key].join('|') \
      + ')=[^&#]*)'
    )
  end

  # Actually strip out the tracking codes/parameters from a URL and
  # return the cleaned URL
  def remove_trackers_hashs_from_url(url)
    # Return if nil
    return url if url.nil?

    # Strip hash params
    url = url.split('#')[0]

    url_pieces = url.split('?')

    # If no params, nothing to modify
    return url if url_pieces.length == 1

    # Go through all the pattern roots
    TRACKER_REGEXES_BY_ROOT.each_key do |key|
      # If we see the root in the params part, then we should probably
      # try to do some replacements
      if url_pieces[1].include?(key)
        url_pieces[1] = url_pieces[1].gsub(TRACKER_REGEXES_BY_ROOT[key], '')
      end
    end

    # If we've collapsed the URL to the point where there's an '&'
    # against the '?' then we need to get rid of that.
    url_pieces[1][0] = '' while url_pieces[1][0] == '&'

    url_pieces.reject!(&:empty?)

    url_pieces[1] ? url_pieces.join('?') : url_pieces[0]
  end

  module_function :remove_trackers_hashs_from_url
end
