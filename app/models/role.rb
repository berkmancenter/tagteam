# frozen_string_literal: true
class Role < ActiveRecord::Base
  acts_as_authorization_role join_table_name: :roles_users
  acts_as_api do |c|
    c.allow_jsonp_callback = true
  end
  has_and_belongs_to_many :users, join_table: :roles_users
  api_accessible :default do |t|
    t.add :id
    t.add :name
    t.add :authorizable_type
    t.add :authorizable_id
  end

  validates :name, presence: true
  attr_accessible :authorizable, :name

  def self.title
    'Role'
  end
end
