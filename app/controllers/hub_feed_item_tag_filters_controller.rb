# Allows Hub owners to add HubFeedItemTagFilters to a FeedItem.
class HubFeedItemTagFiltersController < ApplicationController
  caches_action :index, :unless => Proc.new{|c| current_user }, :expires_in => Tagteam::Application.config.default_action_cache_time, :cache_path => Proc.new{ 
    Digest::MD5.hexdigest(request.fullpath + "&per_page=" + get_per_page)
  }

  access_control do
    allow all, :to => [:index]
    allow :owner, :of => :hub
    allow :hub_feed_item_tag_filterer, :to => [:new, :create]
    allow :owner, :of => :hub_feed_item_tag_filter, :to => [:destroy]
    allow :superadmin
  end

  #A list of filters on this FeedItem in a Hub..
  def index
    load_feed_item
    @hub_feed_item_tag_filters = @feed_item.hub_feed_item_tag_filters.all(:conditions => {:hub_id => @hub.id})
    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default,  :json => @hub_feed_item_tag_filters }
      format.xml{ render_for_api :default,  :xml => @hub_feed_item_tag_filters }
    end
  end

  def new
    load_feed_item
    @hub_feed_item_tag_filter = HubFeedItemTagFilter.new(:hub => @hub)
  end

  def create
    load_feed_item
    # Add the three types of filters here -
    # AddTagFilter
    # DeleteTagFilter
    # ModifyTagFilter

    filter_type_model = params[:filter_type].constantize

    @hub_feed_item_tag_filter = HubFeedItemTagFilter.new()
    @hub_feed_item_tag_filter.hub_id = @hub.id
    @hub_feed_item_tag_filter.feed_item_id = @feed_item.id
    @hub_feed_item_tag_filter.created_by = current_user

    if filter_type_model == ModifyTagFilter
      if params[:tag_id].blank?
        modify_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:modify_tag].downcase)
        params[:tag_id] = modify_tag.id
      end
      new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
      @hub_feed_item_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id], :new_tag_id => new_tag.id)
      current_user.owned_taggings.where(:tag_id => params[:tag_id]).destroy_all
      current_user.tag @feed_item, :with => new_tag, :on => "hub_#{@hub.id}"

    elsif (filter_type_model == AddTagFilter) && params[:tag_id].blank?
      new_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
      @hub_feed_item_tag_filter.filter = filter_type_model.new(:tag_id => new_tag.id)
      current_user.tag @feed_item, :with => new_tag, :on => "hub_#{@hub.id}"

    else
      if params[:tag_id].blank?
        delete_tag = ActsAsTaggableOn::Tag.find_or_create_by_name(params[:new_tag].downcase)
        params[:tag_id] = delete_tag.id
      end
      @hub_feed_item_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id])
      current_user.owned_taggings.where(:tag_id => params[:tag_id]).destroy_all
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
    load_feed_item
    load_hub_feed_item_tag_filter
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
  end

  def load_hub_feed_item_tag_filter
    @hub_feed_item_tag_filter = HubFeedItemTagFilter.find(params[:id])
  end

end
