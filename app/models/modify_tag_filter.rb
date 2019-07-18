# frozen_string_literal: true

# ModifyTagFilter model to distinguish modifytagfilter
class ModifyTagFilter < TagFilter
  validates :new_tag_id, presence: true
  validate :new_tag_id do
    terminating_tag_filter = ModifyTagFilter.find_recursive(self.hub_id, self.new_tag.name)
    if terminating_tag_filter.present? && terminating_tag_filter.new_tag.name == self.tag.name
      errors.add(:base, "New filter can't create an infinite loop of tag filters")
    end
    if new_tag_id == tag_id
      errors.add(:new_tag_id, " can't be the same as the original tag")
    end
  end

  attr_accessible :new_tag_id

  api_accessible :default do |t|
    t.add :new_tag
  end

  # Options are either item_ids passed in, or nothing passed in
  def apply(item_ids = [])
    # Wildcard replacement
    if tag.name.include?('*')
      apply_wildcard(item_ids)
    else
      apply_simple(item_ids)
    end
  end

  def apply_simple(item_ids = [])
    if item_ids.any?
      item_ids &= scope.taggable_items.pluck(:id)
      items = FeedItem.where(id: item_ids).tagged_with(tag.name, on: hub.tagging_key)
    else
      items = scope.taggable_items.tagged_with(tag.name, on: hub.tagging_key)
    end

    # This deactivates old and duplicate tags, which forces the cache to clear
    deactivate_taggings!(items.map(&:id))

    # Mass insert doesn't work on really large inserts
    # values = items.map { |item| "(#{new_tag.id},#{item.id},'FeedItem',#{self.id},'TagFilter','#{hub.tagging_key}')" }.join(',')
    # ActiveRecord::Base.connection.execute("INSERT INTO taggings (tag_id, taggable_id, taggable_type, tagger_id, tagger_type, context) VALUES #{values}")
    # items.each { |item| item.solr_index }
    items.each do |item|
      new_tagging = item.taggings.build(tag: new_tag, tagger: self, context: hub.tagging_key)
      if new_tagging.valid?
        new_tagging.save!
        item.solr_index
      end
    end

    update_column(:applied, true)
  end

  def apply_wildcard(item_ids = [])
    items = item_ids.any? ? FeedItem.where(id: item_ids) : scope.taggable_items
    items_ids = items.pluck(:id)
    queried_tag_name = tag.name.tr('*', '%')

    filtered_taggings = ActsAsTaggableOn::Tagging
                        .joins(:tag)
                        .where('tags.name LIKE ?', queried_tag_name)
                        .where(
                          taggable_id: items_ids,
                          context: hub.tagging_key
                        )

    filtered_taggings_ids = filtered_taggings.pluck(:id)
    filtered_item_ids = filtered_taggings.pluck(:taggable_id)
    filtered_items = items.where(id: filtered_item_ids)

    filter_from_in_parts = tag.name.split(/(\*)/)
    filter_from_in_parts.map! do |filter_part|
      if filter_part == '*'
        '(.*)'
      else
        '(' + Regexp.quote(filter_part) + ')'
      end
    end
    filter_from_regex = Regexp.new(filter_from_in_parts.join)
    filter_to_parts = new_tag.name.split(/(\*)/)

    filtered_items.each_with_index do |item, item_index|
      if item_index % 100 == 0
        GC.start
      end

      taggings_to_change = item.taggings.select { |item_tagging| filtered_taggings_ids.include?(item_tagging.id) }

      taggings_to_change.each do |tagging_to_change|
        tag_to_change = tagging_to_change.tag.name
        tag_to_change_parts = tag_to_change.match(filter_from_regex).captures
        new_tag_name_parts = []

        filter_to_parts.each_with_index do |filter_to_part, index|
          if filter_to_part == '*'
            new_tag_name_parts << tag_to_change_parts[index]
          else
            new_tag_name_parts << filter_to_part
          end
        end

        new_tag_name_joined = new_tag_name_parts.join
        new_tag_name_object = ActsAsTaggableOn::Tag.find_or_create_by_name_normalized(new_tag_name_joined)

        deactivate_tagging(tagging_to_change)

        new_tagging = item.taggings.build(tag: new_tag_name_object, tagger: self, context: hub.tagging_key)
        if new_tagging.valid?
          new_tagging.save!
          item.solr_index
        end
      end
    end

    update_column(:applied, true)
  end

  def deactivates_taggings(item_ids)
    taggings = ActsAsTaggableOn::Tagging.arel_table

    # Deactivates any taggings that have the old tag
    old_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
        taggings[:tag_id].eq(tag.id)
      ).and(
        taggings[:taggable_type].eq('FeedItem')
      ).and(
        taggings[:taggable_id].in(item_ids)
      )
    )

    # Deactivates any taggings that result in the same tag on the same item
    # For example, if an item came in with tags 'tag1' and 'tag2', and this
    # filter changed 'tag1' to 'tag2', this deactivates 'tag2'.
    duplicate_tag = taggings.grouping(
      taggings[:context].eq(hub.tagging_key).and(
        taggings[:tag_id].eq(new_tag.id)
      ).and(
        taggings[:taggable_type].eq('FeedItem')
      ).and(
        taggings[:taggable_id].in(item_ids)
      )
    )

    ActsAsTaggableOn::Tagging.where(old_tag.or(duplicate_tag))
  end

  def simulate(tag_list)
    tag_list.map { |t| t == tag.name ? new_tag.name : t }.uniq
  end

  def filters_before
    previous = hub.all_tag_filters.where(
      "((type = 'ModifyTagFilter' AND new_tag_id = :tag_id) OR
        (type = 'AddTagFilter' AND tag_id = :tag_id))
       AND updated_at < :updated_at",
      tag_id: tag.id, updated_at: updated_at
    ).last
    previous ? previous.filters_before + [previous] : []
  end

  def filters_after
    subsequent = hub.all_tag_filters.where(
      "type IN ('ModifyTagFilter', 'DeleteTagFilter') AND
      tag_id = ? AND updated_at > ?", new_tag.id, updated_at
    ).first
    subsequent ? [subsequent] + subsequent.filters_after : []
  end

  def tag_changes
    { tags_modified: [tag, new_tag] }
  end

  def self.find_recursive(hub_id, tag_name, filter = nil)
    tag = ActsAsTaggableOn::Tag.find_by_name_normalized(tag_name)
    return filter if tag.nil?

    new_filter = self.where(scope_type: 'Hub', scope_id: hub_id, tag_id: tag.id).where.not(type: 'SupplementTagFilter')
    return filter if new_filter.empty?

    find_recursive(hub_id, new_filter.first.new_tag.name, new_filter.first)
  end
end
