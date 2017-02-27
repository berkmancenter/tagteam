# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:tags, :user_tags]
  before_action :load_user, only: [:roles_on]

  after_action :verify_authorized

  def tags
    @hub = Hub.find(params[:hub_id])
    breadcrumbs.add @hub, hub_path(@hub)
    @user = User.find_by(username: params[:username])
    authorize @user
    @show_auto_discovery_params = hub_user_tags_rss_url(@hub, @user)
    @feed_items = ActsAsTaggableOn::Tagging.where(context: "hub_#{@hub.id}",
                                                  taggable_type: 'FeedItem',
                                                  tagger_id: @user,
                                                  tagger_type: 'User')
                                           .paginate(page: params[:page], per_page: get_per_page)
    render layout: !request.xhr?
  end

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
    breadcrumbs.add 'Users', users_path
    @user = User.find(params[:id])
    authorize @user
    render layout: 'tabs'
  end

  def index
    authorize User
    breadcrumbs.add 'Users', users_path
    @users = policy_scope(User).paginate(page: params[:page], per_page: get_per_page)
  end

  def destroy
    @user = User.find(params[:id])
    authorize @user
    @user.destroy
    flash[:notice] = 'Deleted that user'
    respond_to do |format|
      format.html do
        redirect_to action: :index
      end
    end
  end

  def autocomplete
    authorize User

    @search = User.search do
      fulltext params[:term]
    end
    respond_to do |format|
      format.json do
        # Should probably change this to use render_for_api
        render json: @search.results.collect { |r| { id: r.id, label: r.username.to_s } }
      end
    end
  rescue
    render plain: 'Please try a different search term', layout: !request.xhr?
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
end
