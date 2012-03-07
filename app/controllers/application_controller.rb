class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_breadcrumbs

  layout :layout_by_resource

  def get_per_page
    params[:per_page] || cookies[:per_page] || DEFAULT_TAGTEAM_PER_PAGE
  end

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
