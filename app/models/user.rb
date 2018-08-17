# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_tagger
  has_many :hub_user_notifications
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  acts_as_authorization_subject association_name: :roles, join_table_name: :roles_users
  validates :username, uniqueness: true

  # This should be a url friendly username because it's used to see the user's tags
  validates :username, format: { with: /\A[A-Za-z0-9_-]+\z/, message: 'Usernames may only contain letters, numbers, underscores, and hyphens.' }

  validate :blacklisted_domains
  validates :terms_of_service, acceptance: true
  validates :signup_reason, presence: true, unless: :auto_approved?, on: :create
  before_create do
    self.skip_confirmation_notification!
    self.approved = auto_approved?
  end
  after_update do
    if self.approved_changed? && self.approved
      self.send_confirmation_instructions
    end
  end

  scope :unapproved, -> { where(approved: false) }
  scope :superadmin, -> { joins(:roles).where('roles.name = ?', :superadmin).distinct }

  searchable do
    text :first_name, :last_name, :email, :url, :username
    string :username
    string :email
    string :first_name
    string :last_name
    string :url
    boolean :approved
    time :confirmed_at
  end

  def things_i_have_roles_on
    roles.select(:authorizable_type).where(["name = ? AND authorizable_id is not null AND authorizable_type not in('Feed')", 'owner']).group(:authorizable_type).collect(&:authorizable_type).sort.collect(&:constantize)
  end

  # Looks for objects of the class_of_interest owned by this user.
  def my(class_of_interest = Hub)
    roles.includes(:authorizable).where(authorizable_type: class_of_interest.name, name: 'owner').collect(&:authorizable)
  end

  # Looks for objects of the class_of_interest in a specific hub owned by this user. Not all objects have a direct relationship to a hub so this won't necesssarily work everywhere.
  def my_objects_in(class_of_interest = Hub, hub = Hub.first)
    roles.includes(:authorizable).where(authorizable_type: class_of_interest.name, name: 'owner').collect(&:authorizable).select { |o| o.hub_id == hub.id }
  end

  def my_bookmarkable_hubs
    roles.where(authorizable_type: 'Hub', name: %i[owner bookmarker]).collect(&:authorizable)
  end

  def is?(role_name, obj = nil)
    # This allows us to accept strings or arrays.
    role_names = [role_name].flatten.uniq
    gen_role_cache
    role_names.each do |r|
      unless @role_cache["#{obj.nil? ? '' : obj.class.name}-#{obj.nil? ? '' : obj.id}-#{r}"].nil?
        return true
      end
    end
    false
  end

  def my_bookmarking_bookmark_collections_in(hub_id)
    Feed.select('DISTINCT feeds.*').joins(accepted_roles: [:users]).joins(:hub_feeds).where(['roles.name = ? and roles.authorizable_type = ? and roles_users.user_id = ? and hub_feeds.hub_id = ? and feeds.bookmarking_feed = ?', 'owner', 'Feed', (blank? ? nil : id), hub_id, true]).order('created_at desc')
  end

  def get_default_bookmarking_bookmark_collection_for(hub_id)
    bookmark_collections = my_bookmarking_bookmark_collections_in(hub_id)
    if bookmark_collections.blank?
      feed = Feed.new
      feed.bookmarking_feed = true
      feed.title = "#{username}'s bookmarks"
      feed.feed_url = 'not applicable'
      feed.save

      has_role!(:owner, feed)
      has_role!(:creator, feed)

      hf = HubFeed.new
      hf.hub_id = hub_id
      hf.feed_id = feed.id
      hf.save

      has_role!(:owner, hf)
      has_role!(:creator, hf)

      feed
    else
      bookmark_collections.first
    end
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)

    if login
      where(conditions).where([
                                'lower(username) = :value OR lower(email) = :value',
                                { value: login.downcase }
                              ]).first
    elsif conditions[:username].nil?
      where(conditions).first
    else
      where(username: conditions[:username]).first
    end
  end

  def self.title
    'User account'
  end

  def display_name
    tmp_name = "#{first_name} #{last_name}"
    tmp_name.blank? ? email : tmp_name
  end

  # Override Devise to include support for user approval
  def active_for_authentication?
    super && approved?
  end

  # Override Devise to include support for user approval
  def inactive_message
    approved? ? super : :unapproved
  end

  def edu_email?
    email.strip.end_with?('edu')
  end

  def notifications_for_hub?(hub)
    hub_user_notification = hub_user_notifications.find_by(hub: hub)

    return true if hub_user_notification.blank?

    hub_user_notification.notify_about_modifications?
  end

  def application_roles
    roles.where(authorizable_type: nil).order(:name)
  end

  def superadmin?
    has_role?(:superadmin)
  end

  protected

  def gen_role_cache
    return if @role_cache.present?

    logger.warn('regenerating role cache')
    @role_cache = {}
    roles.each do |r|
      @role_cache["#{r.authorizable_type}-#{r.authorizable_id}-#{r.name}"] = 1
    end
  end

  def is_whitelisted?(setting)
    (setting&.whitelisted_domains&.include?(domain) || setting&.whitelisted_domains.any? { |b_domain| domain.match?(/\.#{b_domain}/) }) 
  end

  def is_blacklisted?(setting)
    (setting&.blacklisted_domains&.include?(domain) || setting&.blacklisted_domains.any? { |b_domain| domain.match?(/\.#{b_domain}/) }) 
  end

  # checks if user should be auto approved
  def auto_approved?
    setting = Admin::Setting.first_or_initialize

    # not auto approved if require_admin_approval_for_all is true
    return false if setting.require_admin_approval_for_all

    # else auto approved if user is from whitelisted domain
    # or if user is not from blacklisted domain
    is_whitelisted?(setting) || (setting&.whitelisted_domains.empty? && !is_blacklisted?(setting))
  end

  def blacklisted_domains
    setting = Admin::Setting.first_or_initialize

    if !setting&.require_admin_approval_for_all && is_blacklisted?(setting)
      errors.add(:base, 'Your domain is blacklisted by admin. You can not register with that email.')
    end
  end

  def domain
    Mail::Address.new(email).domain
  end
end
