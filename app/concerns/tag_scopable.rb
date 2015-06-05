module TagScopable
  extend ActiveSupport::Concern

  included do
    class_eval do
      has_many :tag_filters, as: :scope,
        dependent: :destroy, order: 'updated_at DESC'
    end
  end
end
