class FeedItem < ActiveRecord::Base
  acts_as_taggable

  include ModelExtensions
  before_validation do
    auto_strip_tags(:description)
    auto_sanitize_html(:content)
    auto_truncate_columns(:title,:url,:guid,:authors,:contributors,:description,:content,:rights)
  end

  searchable do
    text :title, :content, :url, :guid, :authors, :contributors, :rights
    integer :hub_ids, :multiple => true

    string :title
    string :url
    string :guid
    string :authors
    string :contributors
    string :description
    string :rights
    string :tag_list, :multiple => true
    time :date_published
    time :last_updated
  end

  validates_uniqueness_of :url

  has_and_belongs_to_many :feed_retrievals
  has_and_belongs_to_many :feeds
  has_many :hub_feed_item_tag_filters, :dependent => :destroy, :order => :position

  def hub_feeds(hub = Hub.first)
    # TODO Optimize via multi-table joins?
    hf = HubFeed.find(:all, :conditions => {:hub_id => hub.id, :feed_id => self.feeds.collect{|f| f.id}})
  end

  def hubs
    # TODO Optimize via multi-table joins
    hf = self.hub_feeds
    (hf.empty?) ? [] : hf.collect{|hf| hf.hub}.flatten.uniq.compact
  end

  def hub_ids
    (self.hubs.empty?) ? [] : self.hubs.collect{|h| h.id}
  end

  def update_filtered_tags
    hs = self.hubs
    hs.each do |h|
      self.render_filtered_tags_for_hub(h)
    end
  end

  def render_filtered_tags_for_hub(hub = Hub.first)
    #"tag_list" is the source list of tags directly from RSS/Atom feeds.
    tag_list_for_filtering = self.tag_list.dup

    #Hub tags
    if ! hub.hub_tag_filters.blank?
      hub.hub_tag_filters.each do|htf|
        htf.filter.act(tag_list_for_filtering)
      end
    end

    #Hub feed tags
    hfs = self.hub_feeds(hub)
    hfs.each do|hf|
      if ! hf.hub_feed_tag_filters.blank?
        hf.hub_feed_tag_filters.each do |hftf|
          hftf.filter.act(tag_list_for_filtering)
        end
      end
    end
    #Hub feed item filters
    self.hub_feed_item_tag_filters.find(:all, :conditions => {:hub_id => hub.id}).each do|hfitf|
      hfitf.filter.act(tag_list_for_filtering)
    end
    self.set_tag_list_on("hub_#{hub.id}".to_sym, tag_list_for_filtering.join(','))
    self.save
    tag_list_for_filtering
  end

  def to_s
    "#{title}"
  end

  alias :display_title :to_s

  def items
    [self]
  end

  def mini_icon
    %q|<span class="ui-silk inline ui-silk-application-view-list"></span>|
  end

end
