# frozen_string_literal: true

class DeactivatedTagging < ApplicationRecord
  belongs_to :deactivator, polymorphic: true, autosave: false, optional: true

  def reactivate
    # if feed item already has deactivated tag, destroy deactivated tag and return
    tagging = ActsAsTaggableOn::Tagging.where({ tag_id: tagging_attributes['tag_id'], taggable_id: tagging_attributes['taggable_id'], taggable_type: 'FeedItem' })
    if tagging.any?
      DeactivatedTagging.transaction do
        destroy
      end
    else
      tagging = ActsAsTaggableOn::Tagging.find_or_initialize_by(tagging_attributes)
      DeactivatedTagging.transaction do
        tagging.save!
        destroy
      end
    end
  end

  def tagging_attributes
    tagging_attrs = attributes.except('deactivator_id', 'deactivator_type')

    tagging_hash = {}
    %w[id taggable_type taggable_id tagger_type tagger_id context tag_id].each do |attribute|
      tagging_hash[attribute] = tagging_attrs[attribute]
    end

    tagging_hash
  end
end
