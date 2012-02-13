class DocumentationsController < ApplicationController
  before_filter :load_documentation, :except => [:index, :new, :create]

  access_control do
    allow all, :to => [:index, :show]
    allow :superadmin
  end

  def index
    @documentation = Documentation.find(:all)
  end

  def show
    render :layout => ! request.xhr?
  end

  def new
    @documentation = Documentation.new
    render :layout => ! request.xhr?
  end

  def create
    @documentation = Documentation.new
    @documentation.attributes = params[:documentation]
    respond_to do|format|
      if @documentation.save
        current_user.has_role!(:owner, @documentation)
        current_user.has_role!(:creator, @documentation)
        flash[:notice] = 'Added that bit of documentation.'
        format.html {redirect_to documentation_path(@documentation)}
      else
        flash[:error] = 'Could not add that bit of documentation'
        format.html {render :action => :new}
      end
    end
  end
  
  def edit
    render :layout => ! request.xhr?
  end

  def update
    @documentation.attributes = params[:documentation]
    respond_to do|format|
      if @documentation.save
        current_user.has_role!(:editor, @documentation)
        flash[:notice] = 'Updated!'
        format.html {redirect_to documentation_path(@documentation)}
      else
        flash[:error] = 'Couldn\'t update!'
        format.html {render :action => :new}
      end
    end
  end

  def destroy
    @documentation.destroy
    flash[:notice] = 'Deleted that bit of documentation'
    respond_to do|format|
      format.html{
        redirect_to :action => :index
      }
    end
  end

  private

  def load_documentation
    @documentation = Documentation.find(params[:id])
    if current_user
      @is_superadmin = current_user.has_role?(:superadmin)
    end
  end

end
