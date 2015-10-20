class TagFilterObserver < ActiveRecord::Observer
  def after_rollback(tag_filter)
    tag_filter.hub.apply_tag_filters_after(tag_filter)
  end
end
