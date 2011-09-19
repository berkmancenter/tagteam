class FeedItemTag < ActiveRecord::Base
  include ModelExtensions

  has_and_belongs_to_many :feed_items
  validates_uniqueness_of :tag

  searchable do
    text :tag, :description
    string :tag
  end

  def hubs
    # TODO - optimize via find and includes
    feeds = self.feed_items.find(:all, :include => {:feeds => [:hub_feeds]}).collect{|fi| fi.feeds}.flatten.uniq
    hf =  feeds.collect{|f| f.hub_feeds}.flatten.uniq
    (hf.empty?) ? [] : hf.collect{|hf| hf.hub}.flatten.uniq.compact
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
