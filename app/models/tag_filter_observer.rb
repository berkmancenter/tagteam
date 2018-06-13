# frozen_string_literal: true
class TagFilterObserver < ActiveRecord::Observer
  def after_rollback(tag_filter)
    tag_filter.hub.apply_tag_filters_after(tag_filter)
  end

  def after_create(tag_filter)
    if tag_filter.type == 'AddTagFilter' && tag_filter.scope_type == 'FeedItem'
      tag_filter.hub.apply_tag_filters_to_item_async(tag_filter.scope)
    end
  end
end
