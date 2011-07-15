class HubsController < ApplicationController
  before_filter :load_hub, :except => [:index, :new, :create]
  
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
  end
  
  private

  def load_hub
    @hub = Hub.find(params[:id])
  end

end
