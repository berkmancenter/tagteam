# frozen_string_literal: true
class ApplyTagFilters
  include Sidekiq::Worker

  def self.display_name
    'Applying tag filters'
  end

  def perform(filter_ids, item_ids = [], reapply = false)
    filter_ids = [filter_ids] unless filter_ids.respond_to? :each
    item_ids = [item_ids] unless item_ids.respond_to? :each
    return if filter_ids.empty?

    filter_ids.each do |filter_id|
      filter = TagFilter.where(id: filter_id).first

      # This filter might get deleted while it's in the queue to get applied.
      return if filter.nil?

      # If a filter gets applied by another job because the other job was
      # newer (see below), we don't want to needlessly apply this filter again.
      if filter.applied && !reapply
        logger.debug "Filter #{filter.id} already applied and reapply not set"
        return
      end

      filter.hub.apply_tag_filters_until filter unless filter.next_to_apply?

      if item_ids.empty?
        filter.apply
      else
        filter.apply(items: FeedItem.where(id: item_ids))
      end
    end
  end
end
