class ModifyTagFilter < TagFilter
  validates_presence_of :new_tag_id
  validate :new_tag_id do
    if self.new_tag_id == self.tag_id
      self.errors.add(:new_tag_id, " can't be the same as the original tag")
    end
  end

  attr_accessible :new_tag_id

  api_accessible :default do |t|
    t.add :new_tag
  end

  def description
    'Change'
  end

  def apply
    items_in_scope.each do |item|
    end
  end

  def rollback
  end
end
