class UsersController < ApplicationController

  access_control do
    allow all, :to => [:autocomplete]
    allow :superadmin
  end

  def show
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
    @search.execute!
    respond_to do |format|
      format.json { 
        # Should probably change this to use render_for_api
        render :json => @search.results.collect{|r| {:id => r.id, :label => r.email} }
      }
    end
  rescue
    render :text => "Please try a different search term", :layout => ! request.xhr?
  end

end
