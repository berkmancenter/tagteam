# frozen_string_literal: true

class DeactivatedTagging < ApplicationRecord
  belongs_to :deactivator, polymorphic: true, autosave: false

  def reactivate
    tagging = ActsAsTaggableOn::Tagging.new
    tagging_attrs = attributes.except('deactivator_id', 'deactivator_type')

    tagging_attrs.each do |key, value|
      tagging.send("#{key}=", value)
    end

    DeactivatedTagging.transaction do
      tagging.save!
      destroy
    end

    tagging
  end
end
