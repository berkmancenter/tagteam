class Role < ActiveRecord::Base
  acts_as_authorization_role :join_table_name => :roles_users
  acts_as_api do|c|
    c.allow_jsonp_callback = true
  end

  api_accessible :default do |t|
    t.add :id
    t.add :name
    t.add :authorizable_type
    t.add :authorizable_id
  end

  validates_presence_of :name
  attr_accessible :authorizable, :name
end
