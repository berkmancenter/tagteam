class FeedItemObserver < ActiveRecord::Observer
  def after_create(item)
    return if item.skip_tag_copy
    copy_tags_to_hubs(item)
  end

  def copy_tags_to_hubs(item)
    global_context = Rails.application.config.global_tag_context
    item.hubs.each do |hub|
      item.taggings.where(context: global_context).each do |tagging|
        new_tagging = tagging.dup
        new_tagging.context = hub.tagging_key
        new_tagging.save! if new_tagging.valid?
      end
    end
  end
end
