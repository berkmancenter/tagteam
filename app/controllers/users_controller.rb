class UsersController < ApplicationController

  access_control do
    allow all, :to => [:autocomplete]
    allow :superadmin
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
