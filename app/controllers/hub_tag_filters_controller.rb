class HubTagFiltersController < ApplicationController
  before_filter :load_hub, :except => [:new]
  before_filter :load_hub_tag_filter, :except => [:index, :new, :create]

  access_control do
    allow all, :to => [:index]
    allow :owner, :of => :hub
    allow :superadmin, :hubtagfilteradmin, :filteradmin
  end

  def index
    @hub_tag_filters = @hub.hub_tag_filters
    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default,  :json => @hub_tag_filters }
      format.xml{ render_for_api :default,  :xml => @hub_tag_filters }
    end
  end

  def new
    @hub_tag_filter = HubTagFilter.new
  end

  def move_higher
    @hub_tag_filter.move_higher unless @hub_tag_filter.first?
    redirect_to hub_path(@hub) 
  end

  def move_lower
    @hub_tag_filter.move_lower unless @hub_tag_filter.last?
    redirect_to hub_path(@hub) 
  end

  def create
    # Add the three types of filters here -
    # AddTagFilter
    # DeleteTagFilter
    # ModifyTagFilter

    filter_type_model = params[:filter_type].constantize

    @hub_tag_filter = HubTagFilter.new()
    @hub_tag_filter.hub_id = @hub.id

    if filter_type_model == ModifyTagFilter
      if params[:tag_id].blank?
        modify_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:modify_tag].downcase)
        params[:tag_id] = modify_tag.id
      end
      new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
      @hub_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id], :new_tag_id => new_tag.id)

    elsif (filter_type_model == AddTagFilter) && params[:tag_id].blank?
      new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
      @hub_tag_filter.filter = filter_type_model.new(:tag_id => new_tag.id)

    else
      if params[:tag_id].blank?
        delete_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
        params[:tag_id] = delete_tag.id
      end
      @hub_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id])
    end

    respond_to do|format|
      if @hub_tag_filter.save
        current_user.has_role!(:owner, @hub_tag_filter)
        current_user.has_role!(:creator, @hub_tag_filter)
        flash[:notice] = 'Added that filter to this hub.'
        format.html { render :text => "Added a filter for that tag to \"#{@hub.title}\"", :layout => ! request.xhr? }
      end
    end
  rescue Exception => e
    respond_to do|format|
      format.html { render(:text => @hub_tag_filter.errors.full_messages.join('<br/>'), :status => :not_acceptable, :layout => ! request.xhr?) and return }
    end
  end

  def destroy
    @hub_tag_filter.destroy
    flash[:notice] = 'Deleted that hub tag filter'
    respond_to do|format|
      format.html{
        redirect_to hub_path(@hub)
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
