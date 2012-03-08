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

    def my_bookmarking_bookmark_collections_in(hub_id)
      Feed.select('DISTINCT feeds.*').joins(:accepted_roles => [:users]).joins(:hub_feeds).where(['roles.name = ? and roles.authorizable_type = ? and roles_users.user_id = ? and hub_feeds.hub_id = ? and feeds.bookmarking_feed = ?','owner','Feed', ((self.blank?) ? nil : self.id), hub_id, true]).order('created_at desc')
    end

    def get_default_bookmarking_bookmark_collection_for(hub_id)
      bookmark_collections = my_bookmarking_bookmark_collections_in(hub_id)
      if bookmark_collections.blank?
        feed = Feed.new
        feed.bookmarking_feed = true
        feed.title = "#{self.email}'s bookmarks"
        feed.feed_url = 'not applicable'
        feed.save

        self.has_role!(:owner, feed)
        self.has_role!(:creator, feed)

        hf = HubFeed.new
        hf.hub_id = hub_id
        hf.feed_id = feed.id
        hf.save

        self.has_role!(:owner, hf)
        self.has_role!(:creator, hf)
        feed
      else
        bookmark_collections.first
      end
    end

end
