# In-app documentation linked contextually via the ApplicationHelper#documentation helper.
#
# Most validations are contained in the ModelExtensions mixin.
#
class Documentation < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end

  validates_uniqueness_of :match_key
  attr_accessible :id, :match_key, :title, :description, :lang, :created_at, :updated_at

  def display_title
    (self.title.blank?) ? self.match_key : self.title
  end
  alias :to_s :display_title

end
