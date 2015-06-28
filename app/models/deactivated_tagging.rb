class DeactivatedTagging < ActiveRecord::Base
  belongs_to :deactivator, polymorphic: true, autosave: false

  def reactivate
    tagging = ActsAsTaggableOn::Tagging.new
    tagging_attrs = self.attributes.except('deactivator_id', 'deactivator_type')

    tagging_attrs.each do |key, value|
      tagging.send("#{key}=", value)
    end

    DeactivatedTagging.transaction do
      tagging.save!
      self.destroy
    end

    tagging
  end
end
