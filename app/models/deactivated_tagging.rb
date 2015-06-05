class DeactivatedTagging < ActiveRecord::Base
  self.table_name = 'deactivated_taggings'

  def reactivate
    tagging = self.clone.becomes(ActsAsTaggableOn::Tagging)

    DeactivatedTagging.transaction do
      tagging.save
      tagging.update_attribute(:id, self.id)
      self.destroy
    end
  end
end
