class FeedItemsController < ApplicationController
  before_filter :load_hub_feed
  before_filter :load_feed_item, :except => [:index]
  before_filter :add_breadcrumbs, :except => [:index, :content]

  caches_action :content, :related, :index, :show, :unless => Proc.new{|c| current_user && current_user.is?([:owner,:remixer, :hub_feed_item_tag_filterer, :bookmarker], @hub)}, :expires_in => DEFAULT_ACTION_CACHE_TIME, :cache_path => Proc.new{ 
    request.fullpath + "&per_page=" + get_per_page
  }

  access_control do
    allow all
  end

  # Return the full content for a FeedItem,, this could potentially be a large amount of content. Returns html, json, or xml. Action cached for anonymous visitors.
  def content
    breadcrumbs.add @feed_item.title, hub_feed_feed_item_path(@hub_feed,@feed_item)
    respond_to do|format|
      format.html{ render :layout => ! request.xhr?}
      format.json{ render_for_api :with_content, :json => @feed_item}
      format.xml{ render_for_api :with_content, :xml => @feed_item}
    end
  end

  # Uses a solr more_like_this query to find items to related to this one by comparing the title and tag list. Returns html, json, or xml. Action cached for anonymous visitors.
  def related
    @hub_feed = nil
    hub_id = @hub.id
    @related = Sunspot.more_like_this(@feed_item) do
      fields :title, :tag_list
      with :hub_ids, hub_id
      minimum_word_length 3
      paginate :page => params[:page], :per_page => get_per_page
    end
    @related.execute!
    respond_to do|format|
      format.html{ render :layout => ! request.xhr?}
      format.json{ render_for_api :default, :json => (@related.blank?) ? [] : @related.results }
      format.xml{ render_for_api :default, :xml => (@related.blank?) ? [] : @related.results }
    end
  end


  # A paginated list of FeedItems in a HubFeed. Returns html, atom, rss, json, or xml. Action cached for anonymous visitors.
  def index
    @show_auto_discovery_params = hub_feed_feed_items_url(@hub_feed, :format => :rss)
    @feed_items = @hub_feed.feed_items.paginate(:include => [:feeds, :hub_feeds], :order => 'date_published desc', :page => params[:page], :per_page => get_per_page)
    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.atom{ }
      format.rss{ }
      format.json{ render_for_api :default,  :json => @feed_items }
      format.xml{ render_for_api :default,  :xml => @feed_items }
    end
  end

  # A FeedItem. Returns html, json, or xml. Action cached for anonymous visitors.
  def show
    respond_to do |format|
      format.html{
        breadcrumbs.add @feed_item.title, hub_feed_feed_item_path(@hub_feed,@feed_item)
        render :layout => ! request.xhr?
      }
      format.json{ render_for_api :with_content, :json => @feed_item }
      format.xml{ render_for_api :with_content, :xml => @feed_item }
    end
  end


  private

  def load_hub_feed
    @hub_feed = HubFeed.find(params[:hub_feed_id])
    @hub = @hub_feed.hub
  end

  def load_feed_item
    @feed_item = FeedItem.find(params[:id])
  end

  def add_breadcrumbs
    unless @hub_feed.blank?
      breadcrumbs.add @hub.to_s, hub_path(@hub) 
      breadcrumbs.add @hub_feed.to_s, hub_hub_feed_path(@hub,@hub_feed) 
    end
  end

end
