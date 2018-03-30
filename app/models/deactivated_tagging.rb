# frozen_string_literal: true

class DeactivatedTagging < ApplicationRecord
  belongs_to :deactivator, polymorphic: true, autosave: false

  def reactivate
    tagging = ActsAsTaggableOn::Tagging.find_or_initialize_by(tagging_attributes)

    DeactivatedTagging.transaction do
      tagging.save! if tagging.new_record?
      destroy
    end

    tagging
  end

  def tagging_attributes
    tagging_attrs = attributes.except('deactivator_id', 'deactivator_type')

    tagging_hash = {}
    %w[taggable_type taggable_id tagger_type tagger_id context tag_id].each do |attribute|
      tagging_hash[attribute] = tagging_attrs[attribute]
    end

    tagging_hash
  end
end
