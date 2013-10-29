class TagsController < ApplicationController

  before_filter :load_hub
  before_filter :load_tag_from_name, :only => [:rss, :atom, :show, :json, :xml]
  before_filter :load_feed_items_for_rss, :only => [:rss, :atom, :json, :xml]
  before_filter :add_breadcrumbs

  caches_action :rss, :atom, :json, :xml, :autocomplete, :index, :show, :unless => Proc.new{|c| current_user && current_user.is?(:owner, @hub)}, :expires_in => Tagteam::Application.config.default_action_cache_time, :cache_path => Proc.new{ 
    if request.fullpath.match(/tag\/rss/)
      params[:format] = :rss
    elsif request.fullpath.match(/tag\/atom/)
      params[:format] = :atom
    elsif request.fullpath.match(/tag\/json/)
      params[:format] = :json
    elsif request.fullpath.match(/tag\/xml/)
      params[:format] = :xml
    end
    Digest::MD5.hexdigest(request.fullpath + "&per_page=" + get_per_page)
  }

  access_control do
    allow all
  end

  # Autocomplete ActsAsTaggableOn::Tag results for a Hub as json.
  def autocomplete
    hub_id = @hub.id
    @search = ActsAsTaggableOn::Tag.search do
      with :hub_ids, hub_id
      fulltext params[:term]
    end

    @search.execute!

    respond_to do |format|
      format.json { 
        # Should probably change this to use render_for_api
        render :json => @search.results.collect{|r| {:id => r.id, :label => r.name} }
      }
    end
  rescue
    render :text => "Please try a different search term", :layout => ! request.xhr?
  end

  # A paginated list of ActsAsTaggableOn::Tag objects for a Hub. Returns html, json, and xml.
  def index
    if @hub_feed.blank?
      @tags = FeedItem.tag_counts_on(@hub.tagging_key)
    else
      @tags = @hub_feed.feed_items.tag_counts_on(@hub.tagging_key)
    end
    #tag_sorter = TagSorter.new(:tags => @tags, :sort_by => :created_at, :context => @hub.tagging_key, :class => FeedItem)
    tag_sorter = TagSorter.new(:tags => @tags, :sort_by => :frequency)
    @tags = tag_sorter.sort
    respond_to do|format|
      format.html{ render :layout => !request.xhr? }
      format.json{ render_for_api :default, :json => @tags, :root => :tags }
      format.xml{ render_for_api :default, :xml => @tags, :root => :tags }
    end
  end

  # A paginated RSS feed of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag. This doesn't use the normal respond_to / format system because we use names instead of IDs to identify a tag.
  def rss
  end

  # A paginated Atom feed of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def atom
  end

  # A paginated json list of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def json
    render_for_api :default,  :json => @feed_items
  end

  # A paginated xml list of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
  def xml
    render_for_api :default,  :xml => @feed_items
  end

  # A paginated html list of FeedItem objects for a Hub and a ActsAsTaggableOn::Tag.
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
      @tag = ActsAsTaggableOn::Tag.find_by_name_normalized(params[:name])
    else
      @tag = ActsAsTaggableOn::Tag.find_by_id(params[:id])
    end
    if ! @tag
      flash.now[:error] = "We're sorry, but '#{params[:name]}' is not a tag for '#{@hub.title}'"
      unless current_user.blank?
        @my_hubs = current_user.my(Hub)
      end
      @hubs = Hub.paginate(:page => params[:page], :per_page => get_per_page)
      render 'hubs/index', :layout => ! request.xhr?, :status => 404
    end
  end

  def load_feed_items_for_rss
    @feed_items = FeedItem.tagged_with(@tag.name, :on => @hub.tagging_key).limit(50).order('date_published desc')
  end

end
