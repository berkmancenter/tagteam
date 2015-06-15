class TagFilterObserver < ActiveRecord::Observer
  def after_rollback(tag_filter)
    tag_filter.hub.reapply_tag_filters_after(tag_filter)
  end
end
