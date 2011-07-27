class HubsController < ApplicationController
  before_filter :load_hub, :except => [:index, :new, :create]
  before_filter :prep_resources

  access_control do
    allow all, :to => [:index, :show]
    allow logged_in, :to => [:new, :create]
    allow :owner, :of => :hub, :to => [:edit, :update, :destroy]
    allow :superadmin, :hubadmin
  end

  def index
  end

  def show
  end

  def new
    @hub = Hub.new
  end

  def create
    @hub = Hub.new
    @hub.attributes = params[:hub]
    respond_to do|format|
      if @hub.save
        current_user.has_role!(:owner, @hub)
        current_user.has_role!(:creator, @hub)
        flash[:notice] = 'Added that Hub.'
        format.html {render :action => :show}
      else
        flash[:error] = 'Could not add that Hub'
        format.html {render :action => :new}
      end
    end
  end

  def update
  end

  def edit
  end

  def destroy
    @hub.destroy
    flash[:notice] = 'Deleted that hub'
    respond_to do|format|
      format.html{
        redirect_to :action => :index
      }
    end
  end

  private

  def load_hub
    @hub = Hub.find(params[:id])
    logger.warn('hub is: ' + @hub.inspect)
  end

  def prep_resources
  end

end
