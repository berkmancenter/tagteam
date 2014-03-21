# Allow a Hub owner to add HubFeedTagFilters to a HubFeed.
class HubFeedTagFiltersController < ApplicationController
  before_filter :load_hub_feed, :except => [:new]
  before_filter :load_hub_feed_tag_filter, :except => [:index, :new, :create]

  access_control do
    allow all, :to => [:index]
    allow :owner, :of => :hub
    allow :hub_feed_tag_filterer, :to => [:new, :create]
    allow :owner, :of => :hub_feed_tag_filter, :to => [:destroy]
    allow :superadmin
  end

  def index
    @hub_feed_tag_filters = @hub_feed.hub_feed_tag_filters
    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @hub_feed_tag_filters }
      format.xml{ render_for_api :default, :xml => @hub_feed_tag_filters }
    end
  end

  def new
    @hub_feed_tag_filter = HubFeedTagFilter.new
  end

  def create
    # Add the three types of filters here -
    # AddTagFilter
    # DeleteTagFilter
    # ModifyTagFilter

    filter_type_model = params[:filter_type].constantize

    @hub_feed_tag_filter = HubFeedTagFilter.new()
    @hub_feed_tag_filter.hub_feed_id = @hub_feed.id

    if filter_type_model == ModifyTagFilter
      if params[:tag_id].blank?
        modify_tag = find_or_create_tag_by_name(params[:modify_tag])
        params[:tag_id] = modify_tag.id
      end
      old_tag = ActsAsTaggableOn::Tag.find(params[:tag_id])  
      feed_items = FeedItem.tagged_with(old_tag.name, :on => @hub.tagging_key, :owned_by => current_user).select {|fi| fi.hub_feeds.include?(@hub_feed) }
      new_tag = find_or_create_tag_by_name(params[:new_tag])
      @hub_feed_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id], :new_tag_id => new_tag.id)
      feed_items.each do |f|
        f.skip_tag_indexing_after_save = true
        HubFeedItemTagFilter.where(:hub_id => @hub.id, :feed_item_id => f.id).each     {|hf| next if hf.filter.tag_id != params[:tag_id].to_i; hf.filter.destroy; hf.destroy }
        tag_list = f.owner_tags_on(current_user, @hub.tagging_key)
        tag_list = tag_list.select {|t| t.name != old_tag.name }
        tag_list << new_tag
        current_user.tag f, :with => tag_list, :on => "hub_#{@hub.id}"
      end
      @hub.decrement_tag_count(old_tag, FeedItem.tagged_with(old_tag.name, :on => @hub.tagging_key).size)
      @hub.increment_tag_count(new_tag, FeedItem.tagged_with(old_tag.name, :on => @hub.tagging_key).size) 
    elsif (filter_type_model == AddTagFilter) && params[:tag_id].blank?
      # It's a new tag but we didn't get a tag id. Grab the tag manually.
      new_tag = find_or_create_tag_by_name(params[:new_tag])
      @hub_feed_tag_filter.filter = filter_type_model.new(:tag_id => new_tag.id)
      @hub_feed.feed_items.each do |fi|
        fi.skip_tag_indexing_after_save = true
        current_user.tag fi, :with => new_tag, :on => "hub_#{@hub.id}"
      end
      @hub.set_tag_count(new_tag, @hub_feed.feed_items.size) 
    else
      if params[:tag_id].blank?
        delete_tag = find_or_create_tag_by_name(params[:new_tag])
        params[:tag_id] = delete_tag.id
      end

      @hub_feed_tag_filter.filter = filter_type_model.new(:tag_id => params[:tag_id])
      current_user.owned_taggings.where(:tag_id => params[:tag_id]).destroy_all
      if (filter_type_model == DeleteTagFilter)
        @hub.decrement_tag_count(ActsAsTaggableOn::Tag.find(params[:tag_id]), @hub_feed.feed_items.size) 
      end
      if (filter_type_model == AddTagFilter)
        @hub.set_tag_count(ActsAsTaggableOn::Tag.find(params[:tag_id]), @hub_feed.feed_items.size)
      end   
 end

    respond_to do|format|
      if @hub_feed_tag_filter.save
        current_user.has_role!(:owner, @hub_feed_tag_filter)
        current_user.has_role!(:creator, @hub_feed_tag_filter)
        flash[:notice] = 'Added that filter to this hub.'
        format.html { render :text => "Added a filter for that tag to \"#{@hub_feed.display_title}\"", :layout => ! request.xhr? }
      else
        flash[:error] = 'Could not add that hub feed tag filter'
        format.html { render(:text => @hub_feed_tag_filter.errors.full_messages.join('<br/>'), :status => :not_acceptable, :layout => ! request.xhr?) and return }
      end
    end
  end

  def destroy
    @hub_feed_tag_filter.destroy
    flash[:notice] = 'Deleted that hub feed tag filter'
    respond_to do|format|
      format.html{
        redirect_to hub_hub_feed_path(@hub,@hub_feed)
      }
    end
  end

  private

  def load_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub 
  end

  def load_hub_feed_tag_filter
    @hub_feed_tag_filter = HubFeedTagFilter.find(params[:id])
  end

end
