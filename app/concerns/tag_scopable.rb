module TagScopable
  extend ActiveSupport::Concern

  included do
    has_many :tag_filters, as: :scope,
      dependent: :destroy, order: 'updated_at DESC'

    attr_accessor :skip_global_tag_copy
  end

  def tag_filtered?(tag)
    tag_filters.exists?(tag_id: tag.id)
  end

  def copy_global_tags_to_hubs
    global_context = Rails.application.config.global_tag_context
    taggable_items.each do |item|
      item.hubs.each do |hub|
        item.taggings.where(context: global_context).each do |tagging|
          new_tagging = tagging.dup
          new_tagging.context = hub.tagging_key
          new_tagging.save! if new_tagging.valid?
        end
      end
    end
  end
end
