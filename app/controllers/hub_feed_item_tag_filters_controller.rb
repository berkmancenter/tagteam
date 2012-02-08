class HubFeedItemTagFiltersController < ApplicationController
  before_filter :load_feed_item
  before_filter :load_hub_feed_item_tag_filter, :except => [:index, :new, :create]

  access_control do
    allow all, :to => [:index]
    allow :owner, :of => :hub
    allow :superadmin, :hubfeeditemtagfilteradmin, :filteradmin
  end

  def index
    @hub_feed_item_tag_filters = @feed_item.hub_feed_item_tag_filters.all(:conditions => {:hub_id => @hub.id})
    respond_to do |format|
      format.html{
        render :layout => ! request.xhr?
      }
    end
  end

  def new
    @hub_feed_item_tag_filter = HubFeedItemTagFilter.new(:hub => @hub)
  end

  def move_higher
    @hub_feed_item_tag_filter.move_higher unless @hub_feed_item_tag_filter.first?
    redirect_to hub_feed_feed_item_path(@feed_item.hub_feeds.first,@feed_item) 
  end

  def move_lower
    @hub_feed_item_tag_filter.move_lower unless @hub_feed_item_tag_filter.last?
    redirect_to hub_feed_feed_item_path(@feed_item.hub_feeds.first,@feed_item) 
  end

  def create
    # Add the three types of filters here -
    # AddTagFilter
    # DeleteTagFilter
    # ModifyTagFilter

    filter_type_model = params[:filter_type].constantize

    @hub_feed_item_tag_filter = HubFeedItemTagFilter.new()
    @hub_feed_item_tag_filter.hub_id = @hub.id
    @hub_feed_item_tag_filter.feed_item_id = @feed_item.id

    if filter_type_model == ModifyTagFilter
      new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
      @hub_feed_item_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id], :new_tag_id => new_tag.id)

    elsif (filter_type_model == AddTagFilter) && params[:tag_id].blank?
      new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
      @hub_feed_item_tag_filter.filter = filter_type_model.new(:tag_id => new_tag.id)

    else

      @hub_feed_item_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id])
    end

    respond_to do|format|
      if @hub_feed_item_tag_filter.save
        current_user.has_role!(:owner, @hub_feed_item_tag_filter)
        current_user.has_role!(:creator, @hub_feed_item_tag_filter)
        flash[:notice] = 'Added that filter to this hub.'
        format.html { render :text => "Added a filter for that tag to \"#{@feed_item.display_title}\"", :layout => ! request.xhr? }
      else
        flash[:error] = 'Could not add that hub feed tag filter'
        format.html { render(:text => @hub_feed_item_tag_filter.errors.full_messages.join('<br/>'), :status => :not_acceptable, :layout => ! request.xhr?) and return }
      end
    end
  end

  def destroy
    @hub_feed_item_tag_filter.destroy
    flash[:notice] = 'Deleted that hub feed tag filter'
    respond_to do|format|
      format.html{
        redirect_to hub_feed_feed_item_path(@feed_item.hub_feeds.first,@feed_item) 
      }
    end
  end

  private

  def load_feed_item
    @hub = Hub.find(params[:hub_id]) 
    @feed_item = FeedItem.find(params[:feed_item_id])
    @owners = @hub.owners
    @is_owner = @owners.include?(current_user)
  end

  def load_hub_feed_item_tag_filter
    @hub_feed_item_tag_filter = HubFeedItemTagFilter.find(params[:id])
  end

end
