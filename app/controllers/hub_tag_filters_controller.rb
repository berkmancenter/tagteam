class HubTagFiltersController < ApplicationController
  before_filter :load_hub, :except => [:new, :create]
  before_filter :load_hub_tag_filter, :except => [:index, :new, :create]

  access_control do
    allow all, :to => [:index]
    allow :owner, :of => :hub
    allow :superadmin, :hubtagfilteradmin, :filteradmin
  end

  def index
    @hub_tag_filters = @hub.hub_tag_filters
    respond_to do |format|
      format.html{
        render :layout => ! request.xhr?
      }
    end
  end

  def new
    @hub_tag_filter = HubTagFilter.new

  end

  def move_higher
    @hub_tag_filter.move_higher unless @hub_tag_filter.first?
  end

  def move_lower
    @hub_tag_filter.move_lower unless @hub_tag_filter.last?
  end

  def create
    # Add the three types of filters here -
    # AddTagFilter
    # DeleteTagFilter
    # ModifyTagFilter

    @hub_tag_filter = HubTagFilter.new
    @hub_tag_filter.attributes = params[:hub_tag_filter]
    @hub_tag_filter.hub_id = @hub.id
    respond_to do|format|
      if @hub_tag_filter.save
        current_user.has_role!(:owner, @hub_tag_filter)
        current_user.has_role!(:creator, @hub_tag_filter)
        flash[:notice] = 'Added that filter to this hub.'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Could not add that hub tag filter'
        format.html {render :action => :new}
      end
    end
  end

  def destroy
    @hub_tag_filter.destroy
    flash[:notice] = 'Deleted that hub tag filter'
    respond_to do|format|
      format.html{
        redirect_to :action => :index
      }
    end
  end
  
  private

  def load_hub
    @hub = Hub.find(params[:hub_id])
    @owners = @hub.owners
    @is_owner = @owners.include?(current_user)
  end

  def load_hub_tag_filter
    @hub_tag_filter = HubTagFilter.find(params[:id])
  end

end
