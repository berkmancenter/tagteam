class Feed < ActiveRecord::Base
  include FeedUtilities
  include AuthUtilities

  before_save :get_and_parse_feed

end
