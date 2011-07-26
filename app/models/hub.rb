class Hub < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions

  attr_accessible :title, :description, :tag_prefix
  acts_as_authorization_object
  has_many :hub_feeds
  has_many :hub_tag_filters
  has_many :republished_feeds
  has_many :feeds, :through => :hub_feeds


end
