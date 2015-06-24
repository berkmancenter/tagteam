class ApplyTagFilters
  include Sidekiq::Worker

  def perform(filter_ids, item_ids = [])
    filters_by_id = TagFilter.find(filter_ids).index_by(&:id)
    ordered_filters = filter_ids.map { |id| filters_by_id[id] }
    ordered_filters.each do |filter|
      if item_ids.empty?
        filter.apply
      else
        filter.apply(items: FeedItem.where(id: item_ids))
      end
    end
  end
end
