class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_breadcrumbs

  layout :layout_by_resource

  # The per_page setting for pagination can be overrided by cgi parameters but will fall back to the cookie "per_page" or ultimately the DEFAULT_TAGTEAM_PER_PAGE constant defined in config/initializers/tagteam.rb
  def get_per_page
    params[:per_page] || cookies[:per_page] || DEFAULT_TAGTEAM_PER_PAGE
  end

  # Switch the layout when logging in via the bookmarklet.
  def layout_by_resource
    if devise_controller? && resource_name == :user && action_name == 'new' && (session[:user_return_to] && session[:user_return_to].match(/bookmarklet/))
      "bookmarklet"
    else
      "application"
    end
  end

  rescue_from Acl9::AccessDenied do |exception|
    flash[:notice] = 'Please log in'
    session[:user_return_to] = request.original_url
    redirect_to new_user_session_path
  end

  private 
  def init_breadcrumbs
    breadcrumbs.add 'Home', root_path
  end
end
