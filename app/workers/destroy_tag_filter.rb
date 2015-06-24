class DestroyTagFilter
  include Sidekiq::Worker

  def self.display_name
    'Destroying a tag filter'
  end

  def perform(filter_id)
    filter = TagFilter.find(filter_id)
    filter.rollback
    filter.destroy
  end
end
