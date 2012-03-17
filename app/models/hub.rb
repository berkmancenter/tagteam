class Hub < ActiveRecord::Base
  include AuthUtilities
  include ModelExtensions

  before_validation do
    auto_sanitize_html(:description)
  end

  attr_accessible :title, :description, :tag_prefix
  acts_as_authorization_object

  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  has_many :hub_feeds, :dependent => :destroy
  has_many :hub_tag_filters, :dependent => :destroy, :order => :position
  has_many :republished_feeds, :dependent => :destroy, :order => 'created_at desc'
  has_many :feeds, :through => :hub_feeds

  api_accessible :default do |t|
    t.add :id
    t.add :title
    t.add :description
    t.add :created_at
    t.add :updated_at
  end

  def display_title
    self.title
  end

  alias :to_s :display_title

  def tagging_key
    "hub_#{self.id}".to_sym
  end

end
