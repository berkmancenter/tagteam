class FeedItemsController < ApplicationController
  caches_action :controls, :content, :related, :index, :show, :unless => Proc.new{|c| current_user }, :expires_in => Tagteam::Application.config.default_action_cache_time, :cache_path => Proc.new{ 
    Digest::MD5.hexdigest(request.fullpath + "&per_page=" + get_per_page)
  }

  access_control do
    allow all
  end

  def controls
    load_hub_feed
    load_feed_item
    add_breadcrumbs
    render :layout => ! request.xhr?
  end

  # Return the full content for a FeedItem,, this could potentially be a large amount of content. Returns html, json, or xml. Action cached for anonymous visitors.
  def content
    load_hub_feed
    load_feed_item
    breadcrumbs.add @feed_item.to_s, hub_feed_feed_item_path(@hub_feed,@feed_item)
    respond_to do|format|
      format.html{ render :layout => ! request.xhr?}
      format.json{ render_for_api :with_content, :json => @feed_item}
      format.xml{ render_for_api :with_content, :xml => @feed_item}
    end
  end

  # Uses a solr more_like_this query to find items to related to this one by comparing the title and tag list. Returns html, json, or xml. Action cached for anonymous visitors.
  def related
    load_hub_feed
    load_feed_item
    add_breadcrumbs
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
    load_hub_feed
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
    load_hub_feed
    load_feed_item
    add_breadcrumbs
    respond_to do |format|
      format.html{
        if from_search?
          breadcrumbs.add @feed_item.to_s 
        else
          breadcrumbs.add @feed_item.to_s, hub_feed_feed_item_path(@hub_feed,@feed_item)
        end
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

  def from_search?
   request.referer and request.referer.include?("item_search")
  end

  def add_breadcrumbs
    if from_search?
      breadcrumbs.add @hub.to_s, hub_path(@hub) 
      breadcrumbs.add "Search", request.referer
    else
      unless @hub_feed.blank?
        breadcrumbs.add @hub.to_s, hub_path(@hub) 
        breadcrumbs.add @hub_feed.to_s, hub_hub_feed_path(@hub,@hub_feed) 
      end
    end
  end

end
