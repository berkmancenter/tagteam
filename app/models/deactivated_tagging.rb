class DeactivatedTagging < ActiveRecord::Base
  def reactivate
    tagging = ActsAsTaggableOn::Tagging.new
    self.attributes.each do |key, value|
      tagging.send("#{key}=", value)
    end

    DeactivatedTagging.transaction do
      tagging.save
      tagging.update_attribute(:id, self.id)
      tagging.update_attribute(:created_at, self.created_at)
      self.destroy
    end

    tagging
  end
end
