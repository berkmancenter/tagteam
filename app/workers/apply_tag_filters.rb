class ApplyTagFilters
  include Sidekiq::Worker

  def perform(filter_ids: [], item_ids: [])
    TagFilter.where(id: filter_ids).each do |filter|
      filter.apply(items: FeedItem.where(id: item_ids))
    end
  end
end
