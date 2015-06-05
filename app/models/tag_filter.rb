class TagFilter < ActiveRecord::Base
  belongs_to :hub
  belongs_to :scope, polymorphic: true
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'
  belongs_to :new_tag, class_name: 'ActsAsTaggableOn::Tag'
  has_many :taggings, as: :tagger
  has_many :deactivated_taggings, as: :tagger

  include ModelExtensions
  validates_presence_of :tag_id
  validates :scope_type, inclusion: { in: ['Hub', 'HubFeed', 'FeedItem'] }

  attr_accessible :tag_id

  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :tag
  end

  def owner
  end

  def creator
  end

  def items_in_scope
    scope.taggable_items
  end

  def description
    self.class.name.sub('TagFilter', '')
  end

  def css_class
    # Not using description because they css_class and desc differ sometimes
    self.class.name.sub('TagFilter', '').downcase
  end

  def apply
    deactivate_taggings!
    items_in_scope.each do |item|
      item.taggings.create(tag: tag, tagger: self, context: hub.tagging_key)
    end
  end

  def rollback
    reactivate_taggings!
    taggings.destroy_all
    deactivated_taggings.destroy_all
  end

  def deactivate_taggings!
    deactivates_taggings.each(&:deactivate)
  end

  def reactivate_taggings!
    reactivates_taggings.each(&:reactivate)
  end

  def self.title
    "#{self.name.sub('TagFilter', '')} tag filter"
  end
end
