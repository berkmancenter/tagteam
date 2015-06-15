module TaggingDeactivator
  extend ActiveSupport::Concern

  included do
    has_many :self_deactivated_taggings, class_name: 'DeactivatedTagging',
      as: :deactivator
  end

  def deactivate_tagging(tagging)
    deactivated = DeactivatedTagging.new
    tagging.attributes.each do |key, value|
      deactivated.send("#{key}=", value)
    end
    deactivated.deactivator = self

    DeactivatedTagging.transaction do
      deactivated.save!
      deactivated.update_attribute(:id, tagging.id)
      deactivated.update_attribute(:created_at, tagging.created_at)
      tagging.destroy
    end

    deactivated
  end

  def deactivate_taggings!(items: items_in_scope)
    deactivates_taggings(items: items).each do |tagging|
      deactivate_tagging(tagging)
    end
  end

  def reactivates_taggings
    self_deactivated_taggings
  end

  def reactivate_taggings!
    reactivates_taggings.each(&:reactivate)
  end
end
