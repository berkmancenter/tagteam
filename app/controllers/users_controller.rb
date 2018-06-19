# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:hub_items, :tags, :user_tags, :tags_json,
                                              :tags_rss, :tags_atom]
  before_action :load_user, only: [:roles_on]
  before_action :load_hub, only: [:tags, :tags_json, :tags_rss, :tags_atom,
    :hub_items]
  before_action :load_feed_items, only: [:tags, :tags_json, :tags_rss,
                                         :tags_atom]
  before_action :set_home_url, only: [:tags, :tags_json, :tags_rss,
                                      :tags_atom]
  before_action :find_user, only: [:documentation_admin_role, :superadmin_role,
                                   :lock_user, :destroy, :show, :resend_confirmation_token,
                                   :resend_unlock_token]
  after_action :verify_authorized, except: [:hub_items]

  SORT_OPTIONS = {
    'created_at' => -> (rel) { rel.order('created_at') },
    'date_published' => ->(rel) { rel.order('date_published') },
  }.freeze

  SORT_DIR_OPTIONS = %w(asc desc).freeze

  def hub_items
    breadcrumbs.add @hub, hub_path(@hub)
    @user = User.find_by(username: params[:username])

    @hub_feed = @hub.hub_feeds.detect { |hf| hf.owners.include?(@user) }

    redirect_to hub_path(@hub) and return if @hub_feed.nil?

    sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : SORT_OPTIONS.keys.first
    order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first
    @feed_items = SORT_OPTIONS[sort].call(
      @hub_feed
      .feed_items
      .includes(:feeds, :hub_feeds)
      .paginate(page: params[:page], per_page: get_per_page)
    )
    @feed_items = @feed_items.reverse_order if order == 'desc'

    render 'hub_items', layout: request.xhr? ? false : 'tabs'
  end

  def tags
    breadcrumbs.add @hub, hub_path(@hub)
    breadcrumbs.add @user.username, hub_user_hub_items_path(@hub, @user.username)
    if @tag
      breadcrumbs.add @tag.name, hub_user_tags_name_path(
        @hub, @user.username, @tag.name
      )
    end

    template = params[:view] == 'grid' ? 'tags_grid' : 'tags'
    render template, layout: request.xhr? ? false : 'tabs'
  end

  def tags_json
    render_for_api :default, json: @feed_items
  end

  def tags_rss; end

  def tags_atom; end

  def user_tags
    @hub = Hub.find(params[:hub_id])

    breadcrumbs.add @hub, hub_path(@hub)
    @user = User.find_by(username: params[:username])
    authorize @user
    @tag = ActsAsTaggableOn::Tag.find_by(name: params[:tagname])
    @show_auto_discovery_params = hub_user_tags_rss_url(@hub, @user)
    @feed_items = ActsAsTaggableOn::Tagging.where(context: "hub_#{@hub.id}",
                                                  tag_id: @tag,
                                                  taggable_type: 'FeedItem',
                                                  tagger_id: @user,
                                                  tagger_type: 'User')
                                           .paginate(page: params[:page], per_page: get_per_page)
    render :tags, layout: !request.xhr?
  end

  def roles_on
    @roles_on = @user.roles
                     .select([:authorizable_type, :authorizable_id])
                     .includes(:authorizable)
                     .where(authorizable_type: params[:roles_on])
                     .group(:authorizable_type, :authorizable_id)
                     .order(:authorizable_type, :authorizable_id)
                     .paginate(page: params[:page], per_page: get_per_page)

    respond_to do |format|
      format.html { render layout: request.xhr? ? false : 'tabs' }
      format.json { render_for_api :default, json: @roles_on, root: :role }
      format.xml { render_for_api :default, xml: @roles_on, root: :role }
    end
  end

  def resend_unlock_token
    authorize User
    @user.resend_unlock_token
    flash[:notice] = 'We resent the account unlock email to that user.'
    redirect_to request.referer
  rescue Exception => e
    flash[:notice] = 'Woops. We could not send that right now. Please try again later.'
    redirect_to request.referer
  end

  def resend_confirmation_token
    authorize User
    @user.resend_confirmation_token
    flash[:notice] = 'We resent the account confirmation email to that user.'
    redirect_to request.referer
  rescue Exception => e
    flash[:notice] = 'Woops. We could not send that right now. Please try again later.'
    redirect_to request.referer
  end

  def show
    breadcrumbs.add 'Users', admin_users_path
    authorize @user
    render layout: 'tabs'
  end

  def destroy
    #@user = User.find(params[:id])
    authorize @user
    @user.destroy
    flash[:notice] = 'Deleted that user'
    respond_to do |format|
      format.html do
        redirect_to admin_users_path
      end
    end
  end

  def lock_user
    authorize current_user
    if @user.access_locked?
      @user.unlock_access!
      flash[:notice] = 'User has been unlocked successfully'
    else
      @user.lock_access!
      flash[:notice] = 'User has been locked successfully'
    end
    redirect_to user_path
  end

  def superadmin_role
    role = Role.find_or_create_by(name: 'superadmin')
    authorize current_user
    if @user.has_role?(:superadmin)
      @user.roles.destroy(role)
      flash[:notice] = 'Superadmin permission has been revoked for the user'
    else
      @user.roles << role
      flash[:notice] = 'User has been granted superadmin permission'
    end
    redirect_to user_path
  end

  def documentation_admin_role
    role = Role.find_or_create_by(name: 'documentation_admin')
    authorize current_user
    if @user.has_role?(:documentation_admin)
      @user.roles.destroy(role)
      flash[:notice] = 'Documentation Admin permission has been revoked for the user'
    else
      @user.roles << role
      flash[:notice] = 'User has been granted Documentation Admin permission'
    end
    redirect_to user_path
  end

  private

  def load_user
    @user = if current_user.is?(:superadmin)
              User.find params[:id]
            else
              current_user
            end
    authorize @user
  end

  def load_hub
    @hub = Hub.find(params[:hub_id])
  end

  def set_home_url
    @home_url = @tag ? hub_user_tags_name_path(@hub, @user.username, @tag.name) :
      hub_user_hub_items_path(@hub, @user.username)
  end

  def load_feed_items
    authorize User

    @user = User.find_by!(username: params[:username])

    if params[:tagname]
      @tag = ActsAsTaggableOn::Tag.where(name: params[:tagname]).first

      taggings = if params[:deprecated].nil?
                   ActsAsTaggableOn::Tagging.select('DISTINCT ON ("context") *')
                                            .where(context: "hub_#{@hub.id}",
                                                   taggable_type: 'FeedItem',
                                                   tag_id: @tag,
                                                   tagger_id: @user,
                                                   tagger_type: 'User')
                 else
                   Statistics::TaggingsOfUser.run!(
                     user: @user,
                     hub: @hub,
                     tag: @tag,
                     deprecated: true
                   ).map(&:deep_symbolize_keys!)
                 end
      @feed_items = FeedItem.where(id: taggings.pluck(:taggable_id))
                          .paginate(page: params[:page], per_page: get_per_page)
                          .order('date_published DESC')
    else
      @user = User.find_by(username: params[:username])
      @hub_feed = @hub.hub_feeds.detect { |hf| hf.owners.include?(@user) }
      @feed_items = @hub_feed.feed_items
    end
  end

  def find_user
    @user = User.find(params[:id])
  end
end
