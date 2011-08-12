class FeedItem < ActiveRecord::Base
  include ModelExtensions
  before_validation do
    auto_strip_tags(:description)
    auto_sanitize_html(:content)
    auto_truncate_columns(:title,:url,:author,:description,:content,:copyright)
  end

  has_and_belongs_to_many :feed_item_tags

  def tags=(tag_inputs)
    tag_inputs.each do|t|
      self.feed_item_tags << FeedItemTag.find_or_initialize_by_tag(t.downcase)
    end
  end

end
