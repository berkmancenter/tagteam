class FeedItemTag < ActiveRecord::Base
  include ModelExtensions

  has_and_belongs_to_many :feed_items
  validates_uniqueness_of :tag

  searchable do
    text :tag, :description
    string :tag
  end

  def to_s
    "#{tag}"
  end

  def items
    feed_items
  end

  alias :display_title :to_s
  
  def mini_icon
    %q|<span class="ui-silk inline ui-silk-tag-blue"></span>|
  end

end
