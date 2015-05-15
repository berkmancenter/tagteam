module TagFilterable
  extend ActiveSupport::Concern

  def apply_tag_filters
    self
  end

  def tag_filters
    all_filters = hub_tag_filters.all + hub_feed_tag_filters.all +
      hub_feed_item_tag_filters.all
    all_filters.sort_by{ |filter| filter.updated_at }
  end
end
