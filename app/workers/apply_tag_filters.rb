class ApplyTagFilters
  include Sidekiq::Worker

  def self.display_name
    'Applying tag filters'
  end

  def perform(filter_ids, item_ids = [])
    filter_ids = [filter_ids] unless filter_ids.respond_to? :each
    item_ids = [item_ids] unless item_ids.respond_to? :each

    filters_by_id = TagFilter.where(id: filter_ids).index_by(&:id)
    ordered_filters = filter_ids.map { |id| filters_by_id[id] }
    ordered_filters.each do |filter|

      # This filter might get deleted while it's in the queue to get applied.
      return unless filter.persisted?
      unless filter.next_to_apply? 
        raise "Not most recent unapplied filter (#{filter.id}) in " +
          "hub (#{filter.hub_id})" 
      end

      if item_ids.empty?
        filter.apply
      else
        filter.apply(items: FeedItem.where(id: item_ids))
      end
    end
  end
end
