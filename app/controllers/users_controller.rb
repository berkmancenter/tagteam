class UsersController < ApplicationController

  before_filter :load_user, :only => [:roles_on]

  access_control do
    allow all, :to => [:tags]
    allow logged_in, :to => [:roles_on, :autocomplete]
    allow :superadmin
  end

  def tags
    @hub = Hub.find(params[:hub_id])
    breadcrumbs.add @hub, hub_path(@hub)
    @user = User.find_by_username(params[:username])
    @show_auto_discovery_params = hub_user_tags_rss_url(@hub, @user)
    @feed_items = @user.owned_taggings.paginate(:page => params[:page], :per_page => get_per_page)
    render :layout => ! request.xhr?
  end

  def roles_on
    @roles_on = @user.roles.select([:authorizable_type, :authorizable_id]).includes(:authorizable).where(:authorizable_type => params[:roles_on]).group(:authorizable_type, :authorizable_id).order(:authorizable_type, :authorizable_id).paginate(:page => params[:page], :per_page => get_per_page)
    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @roles_on, :root => :role }
      format.xml{ render_for_api :default, :xml => @roles_on, :root => :role }
    end
  end

  def resend_unlock_token
    u = User.find(params[:id])
    u.resend_unlock_token
    flash[:notice] = 'We resent the account unlock email to that user.'
    redirect_to request.referer
  rescue Exception => e
    flash[:notice] = 'Woops. We could not send that right now. Please try again later.'
    redirect_to request.referer
  end

  def resend_confirmation_token
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
  end

  def index
    breadcrumbs.add 'Users', users_path
    @users = User.paginate(:page => params[:page], :per_page => get_per_page)
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:notice] = 'Deleted that user'
    respond_to do|format|
      format.html{
        redirect_to :action => :index
      }
    end
  end

  def autocomplete
    @search = User.search do
      fulltext params[:term]
    end
    respond_to do |format|
      format.json { 
        # Should probably change this to use render_for_api
        render :json => @search.results.collect{|r| {:id => r.id, :label => "#{r.username}"} }
      }
    end
  rescue
    render :text => "Please try a different search term", :layout => ! request.xhr?
  end

  private

  def load_user
    if current_user.is?(:superadmin)
      @user = User.find params[:id]
    else 
      @user = current_user
    end
  end

end
