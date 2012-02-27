class TagsController < ApplicationController

  before_filter :load_hub
  before_filter :load_tag_from_name, :only => [:rss, :atom, :show]
  before_filter :load_feed_items_for_rss, :only => [:rss, :atom]
  before_filter :add_breadcrumbs

  access_control do
    allow all
  end

  def autocomplete
    hub_id = @hub.id
    @search = ActsAsTaggableOn::Tag.search do
      with :hub_ids, hub_id
      fulltext params[:term]
    end

    @search.execute!

    respond_to do |format|
      format.json { 
        render :json => @search.results.collect{|r| {:id => r.name, :label => r.name} }
      }
    end

  end

  def index
    if @hub_feed.blank?
      @tags = FeedItem.tag_counts_on(@hub.tagging_key)
    else
      @tags = @hub_feed.feed_items.tag_counts_on(@hub.tagging_key)
    end
    render :layout => ! request.xhr?
  end

  def rss
  end

  def atom
  end

  def show
    @feed_items = FeedItem.tagged_with(@tag.name, :on => @hub.tagging_key).paginate(:order => 'date_published desc', :page => params[:page], :per_page => get_per_page)
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

  def load_tag_from_name
    if ! params[:name].blank?
      @tag = ActsAsTaggableOn::Tag.find_by_name(params[:name])
    else
      @tag = ActsAsTaggableOn::Tag.find(params[:id])
    end
  end

  def load_feed_items_for_rss
    @feed_items = FeedItem.tagged_with(@tag.name, :on => @hub.tagging_key).limit(50).order('date_published desc')
  end

end
