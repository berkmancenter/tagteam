class DestroyTagFilter
  include Sidekiq::Worker

  def perform(filter_id)
    filter = TagFilter.find(filter_id)
    filter.rollback
    filter.destroy
  end
end
