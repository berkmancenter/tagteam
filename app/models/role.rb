class Role < ActiveRecord::Base
      acts_as_authorization_role :join_table_name => :roles_users
      
      validates_presence_of :name
      attr_accessible :authorizable, :name
end
