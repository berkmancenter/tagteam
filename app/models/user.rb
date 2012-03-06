class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  acts_as_authorization_subject :association_name => :roles, :join_table_name => :roles_users

  def my(class_of_interest = Hub)
    roles.includes(:authorizable).find(:all, :conditions => {:authorizable_type => class_of_interest.name, :name => 'owner'}).collect{|r| r.authorizable}
  rescue
    []
  end

    def is?(role_name, obj)
      self.roles.reject{|r| (r.authorizable_type == obj.class.name && r.authorizable_id == obj.id && r.name == role_name.to_s) ? false : true }.length >= 1
    end

    def my_bookmarking_stacks_in(hub_id)
      Feed.select('DISTINCT feeds.*').joins(:accepted_roles => [:users]).joins(:hub_feeds).where(['roles.name = ? and roles.authorizable_type = ? and roles_users.user_id = ? and hub_feeds.hub_id = ? and feeds.bookmarking_feed = ?','owner','Feed', ((self.blank?) ? nil : self.id), hub_id, true]).order('created_at desc')
    end

end
