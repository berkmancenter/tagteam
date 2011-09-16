class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_breadcrumbs

  private 
  def init_breadcrumbs
    breadcrumbs.add 'Home', root_path
  end
end
