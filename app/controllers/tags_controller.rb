class TagsController < ApplicationController

  before_filter :load_hub
  before_filter :load_tag_from_name, :only => [:rss, :atom, :show, :json]
  before_filter :load_feed_items_for_rss, :only => [:rss, :atom, :json]
  before_filter :add_breadcrumbs

  caches_action :rss, :atom, :json, :autocomplete, :index, :show, :unless => Proc.new{|c| current_user && current_user.is?(:owner, @hub)}, :expires_in => 15.minutes, :cache_path => Proc.new{ 
    if request.fullpath.match(/tag\/rss/)
      params[:format] = :rss
    elsif request.fullpath.match(/tag\/atom/)
      params[:format] = :atom
    end
    request.fullpath + "&per_page=" + get_per_page
  }

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
        render :json => @search.results.collect{|r| {:id => r.id, :label => r.name} }
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

  def json
    render_for_api :default,  :json => @feed_items, :callback => params[:callback] 
  end

  def show
    @show_auto_discovery_params = hub_tag_rss_url(@hub, @tag.name)
    @feed_items = FeedItem.tagged_with(@tag.name, :on => @hub.tagging_key).paginate(:order => 'date_published desc', :page => params[:page], :per_page => get_per_page)
    render :layout => ! request.xhr?
  end


  private

  def load_hub
    if ! params[:hub_feed_id].blank?
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @hub = @hub_feed.hub
    else 
      @hub = Hub.find(params[:hub_id])
    end
  end

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
