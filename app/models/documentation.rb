class Documentation < ActiveRecord::Base
  # most validations are in ModelExtensions
  include ModelExtensions
  include AuthUtilities
  validates_uniqueness_of :match_key

  def display_title
    (self.title.blank?) ? self.match_key : self.title
  end
  alias :to_s :display_title

end
