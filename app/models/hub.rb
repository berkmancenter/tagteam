class Hub < ActiveRecord::Base
  include AuthUtilities

  validates_presence_of :title
  attr_accessible :title, :description, :tag_prefix
  acts_as_authorization_object


end
