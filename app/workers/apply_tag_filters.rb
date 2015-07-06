class ApplyTagFilters
  include Sidekiq::Worker

  def self.display_name
    'Applying tag filters'
  end

  def perform(filter_ids, item_ids = [])
    filter_ids = [filter_ids] unless filter_ids.respond_to? :each
    item_ids = [item_ids] unless item_ids.respond_to? :each
    return if filter_ids.empty?

    filter_ids.each do |filter_id|
      filter = TagFilter.where(id: filter_id).first

      # This filter might get deleted while it's in the queue to get applied.
      return if filter.nil?
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
