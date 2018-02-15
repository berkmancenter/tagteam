# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:tags, :user_tags, :tags_json,
                                              :tags_rss, :tags_atom]
  before_action :load_user, only: [:roles_on]
  before_action :load_hub, only: [:tags, :tags_json, :tags_rss, :tags_atom]
  before_action :load_feed_items, only: [:tags, :tags_json, :tags_rss,
                                         :tags_atom]
  before_action :set_home_url, only: [:tags, :tags_json, :tags_rss,
                                      :tags_atom]
  after_action :verify_authorized

  def tags
    breadcrumbs.add @hub, hub_path(@hub)
    breadcrumbs.add @user.username, hub_user_tags_path(@hub, @user.username)
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
    u = User.find(params[:id])
    u.resend_unlock_token
    flash[:notice] = 'We resent the account unlock email to that user.'
    redirect_to request.referer
  rescue Exception => e
    flash[:notice] = 'Woops. We could not send that right now. Please try again later.'
    redirect_to request.referer
  end

  def resend_confirmation_token
    authorize User
    u = User.find(params[:id])
    u.resend_confirmation_token
    flash[:notice] = 'We resent the account confirmation email to that user.'
    redirect_to request.referer
  rescue Exception => e
    flash[:notice] = 'Woops. We could not send that right now. Please try again later.'
    redirect_to request.referer
  end

  def show
    breadcrumbs.add 'users', admin_users_path
    @user = User.find(params[:id])
    authorize @user
    render layout: 'tabs'
  end

  def destroy
    @user = User.find(params[:id])
    authorize @user
    @user.destroy
    flash[:notice] = 'Deleted that user'
    respond_to do |format|
      format.html do
        redirect_to admin_users_path
      end
    end
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
    @home_url = if @tag
                  hub_user_tags_name_path(
                    @hub, @user.username, @tag.name
                  )
                else
                  hub_user_tags_path(@hub, @user.username)
                end
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
    else
      taggings = ActsAsTaggableOn::Tagging.select('DISTINCT ON ("context") *')
                                          .where(context: "hub_#{@hub.id}",
                                                 taggable_type: 'FeedItem',
                                                 tagger_id: @user,
                                                 tagger_type: 'User')
    end

    @feed_items = FeedItem.where(id: taggings.pluck(:taggable_id))
                          .paginate(page: params[:page], per_page: get_per_page)
  end
end
