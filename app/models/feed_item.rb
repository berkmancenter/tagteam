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

  def hubs
    # TODO Optimize via multi-table joins
    hf = self.feeds.find(:all, :include => [:hub_feeds => [:hub]]).collect{|f| f.hub_feeds}.flatten.uniq
    (hf.empty?) ? [] : hf.collect{|hf| hf.hub}.flatten.uniq.compact
  end

  def hub_ids
    (self.hubs.empty?) ? [] : self.hubs.collect{|h| h.id}
  end

  def updated_filtered_tags(hub = Hub.first)
  end

  def filtered_tags(hub = Hub.first)
    tags = self.tags.dup
    if ! hub.hub_tag_filters.blank?
      hub.hub_tag_filters.each do|htf|
        htf.filter.act(tags)
      end
    end
    tags
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
