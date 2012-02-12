class TagsController < ApplicationController

  before_filter :load_hub
  before_filter :add_breadcrumbs

  access_control do
    allow all
  end

  def index
    if @hub_feed.blank?
      @tags = FeedItem.tag_counts_on(@hub.tagging_key)
    else
      @tags = @hub_feed.feed_items.tag_counts_on(@hub.tagging_key)
    end
    render :layout => ! request.xhr?
  end

  def show
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    @feed_items = FeedItem.tagged_with(@tag.name, :on => @hub.tagging_key).paginate(:order => 'date_published desc', :page => params[:page], :per_page => params[:per_page])
    render :layout => ! request.xhr?
  end

  def load_hub
    if ! params[:hub_feed_id].blank?
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @hub = @hub_feed.hub
    else 
      @hub = Hub.find(params[:hub_id])
    end
  end

  private

  def add_breadcrumbs
    breadcrumbs.add @hub.to_s, hub_path(@hub) 
  end

end
