class Hub < ActiveRecord::Base
  include AuthUtilities

  validates_presence_of :title
  validates_length_of :title, :minimum => 1, :maximum => 255
  validates_length_of :tag_prefix, :maximum => 25

  attr_accessible :title, :description, :tag_prefix
  acts_as_authorization_object


end
