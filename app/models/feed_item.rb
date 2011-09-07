class FeedItem < ActiveRecord::Base

  include ModelExtensions
  before_validation do
    auto_strip_tags(:description)
    auto_sanitize_html(:content)
    auto_truncate_columns(:title,:url,:guid,:author,:contributor,:description,:content,:rights)
  end

  validates_uniqueness_of :url

  has_and_belongs_to_many :feed_item_tags
  has_and_belongs_to_many :feeds

  def tags=(tag_inputs)
    #FIXME - merge tags
    new_tags = []
    tag_inputs.each do|t|
      new_tags << FeedItemTag.find_or_initialize_by_tag(t.downcase)
    end
    self.feed_item_tags = [self.feed_item_tags, new_tags].flatten.uniq.compact
  end

end
