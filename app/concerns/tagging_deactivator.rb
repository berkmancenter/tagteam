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

    deactivated.deactivator = self unless self.new_record?

    DeactivatedTagging.transaction do
      deactivated.save!
      tagging.destroy
    end

    deactivated
  end

  def deactivate_taggings!
    deactivates_taggings.map do |tagging|
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
