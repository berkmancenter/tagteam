class FeedItemTag < ActiveRecord::Base
  include ModelExtensions

  has_and_belongs_to_many :feed_items
  validates_uniqueness_of :tag

  searchable(:include => {:feeds => [:hub_feeds]}) do
    text :tag, :description
    string :tag
    integer :hub_ids, :multiple => true

  end

  def hubs
    # TODO - optimize via find and includes
    feeds = self.feed_items.find(:all, :include => {:feeds => [:hub_feeds]}).collect{|fi| fi.feeds}.flatten.uniq
    hf =  feeds.collect{|f| f.hub_feeds}.flatten.uniq
    (hf.empty?) ? [] : hf.collect{|hf| hf.hub}.flatten.uniq.compact
  end

  def hub_ids
    (self.hubs.empty?) ? [] : self.hubs.collect{|h| h.id}
  end

  def to_s
    "#{tag}"
  end

  def items
    feed_items.find(:all, :include => [:feed_item_tags])
  end

  alias :display_title :to_s
  
  def mini_icon
    %q|<span class="ui-silk inline ui-silk-tag-blue"></span>|
  end

end
