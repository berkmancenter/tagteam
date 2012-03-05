class Documentation < ActiveRecord::Base
  include AuthUtilities
  # most validations are in ModelExtensions
  include ModelExtensions
  before_validation do
    auto_sanitize_html(:description)
  end

  validates_uniqueness_of :match_key
  attr_accessible :match_key, :title, :description, :lang

  def display_title
    (self.title.blank?) ? self.match_key : self.title
  end
  alias :to_s :display_title

end
