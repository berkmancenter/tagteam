class UsersController < ApplicationController

  access_control do
    allow all
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
