# Allow a Hub owner to add HubTagFilters.
class HubFeedsController < ApplicationController
  before_filter :load_hub_feed, :except => [:index, :new, :create, :autocomplete]
  before_filter :load_hub
  before_filter :add_breadcrumbs, :except => [:index, :new, :create, :reschedule_immediately, :autocomplete, :import]
  before_filter :prep_resources

  caches_action :index, :show, :more_details, :autocomplete, :unless => Proc.new{|c| current_user && current_user.is?(:owner, @hub)}, :expires_in => 15.minutes, :cache_path => Proc.new{ 
    request.fullpath + "&per_page=" + get_per_page
  }

  access_control do
    allow all, :to => [:index, :show, :more_details, :autocomplete]
    allow :owner, :of => :hub, :to => [:new, :create, :reschedule_immediately]
    allow :owner, :of => :hub_feed, :to => [:edit, :update, :destroy, :import]
    allow :superadmin, :hub_feed_admin
  end

  def autocomplete
    hub_id = @hub.id
    @search = HubFeed.search do
      with :hub_ids, hub_id
      fulltext params[:term]
    end

    @search.execute!

    respond_to do |format|
      format.json { 
        render :json => @search.results.collect{|r| {:id => r.id, :label => r.display_title} }
      }
    end
  end

  def import
    feed = @hub_feed.feed
    errors = []
    items = []

    if params[:type] == 'connotea_rdf'
      importer = Tagteam::Importer::Connotea.new(params[:import_file])
    elsif params[:type] == 'delicious'
      importer = Tagteam::Importer::Delicious.new(params[:import_file])
    end

    items = importer.parse_items

    items.each do|item|
      feed_item = FeedItem.find_or_initialize_by_url(item[:url])
      [:title, :url, :guid, :authors, :contributors, :description, :content, :rights, :date_published, :last_updated].each do|col|
        feed_item.send(%Q|#{col}=|, item[col])
      end
      feed_item.tag_list = [feed_item.tag_list, item[:tag_list].collect{|t| t.downcase[0,255].gsub(/,/,'_')}].flatten.compact.join(',')

      if feed_item.save
        feed_item.accepts_role!(:owner, current_user)
        feed_item.accepts_role!(:creator, current_user)
        if feed.feed_items.nil? || ! feed.feed_items.include?(feed_item)
          feed.feed_items << feed_item
        end
      else
        errors << feed_item.errors.full_messages.join('<br/>')
      end
    end
    feed.save
    Resque.enqueue(HubFeedFeedItemTagRenderer, @hub_feed.id)
    flash[:error] = errors.join('<br/>')
    flash[:notice] = "Imported those items." + ((errors.blank?) ? '' :" Please see the errors below.")
    redirect_to :action => :show
  end

  def more_details
    render :layout => ! request.xhr?
  end

  def reschedule_immediately
    feed = @hub_feed.feed
    feed.next_scheduled_retrieval = Time.now
    feed.save
    flash[:notice] = 'Rescheduled that feed to be re-indexed at the next available opportunity.'
    redirect_to hub_hub_feed_path(@hub,@hub_feed)
  rescue
    flash[:notice] = "We couldn't reschedule that feed."
    redirect_to hub_hub_feed_path(@hub,@hub_feed)
  end

  def index
    @hub_feeds = @hub.hub_feeds.rss.paginate(:page => params[:page], :per_page => get_per_page, :order => 'created_at desc' )
    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @hub_feeds }
      format.xml{ render_for_api :default, :xml => @hub_feeds }
    end
  end

  def show
    @show_auto_discovery_params = hub_feed_feed_items_url(@hub_feed, :format => :rss)
    breadcrumbs.add @hub_feed.display_title, hub_hub_feed_path(@hub,@hub_feed)
  end

  def new
    # Only used to create bookmarking collections.
    # Actual rss feeds are added through the hub controller. Yeah, probably not optimal
    @hub_feed = HubFeed.new
    @hub_feed.hub_id = @hub.id
  end

  def create
    # Only used to create bookmarking collections.
    # Actual rss feeds are added through the hub controller. Yeah, probably not optimal
    @hub_feed = HubFeed.new
    @hub_feed.hub_id = @hub.id

    actual_feed = Feed.new
    actual_feed.bookmarking_feed = true
    actual_feed.feed_url = 'not applicable'
    actual_feed.title = params[:hub_feed][:title]
    current_user.has_role!(:owner, actual_feed)
    actual_feed.save

    @hub_feed.feed = actual_feed
    @hub_feed.attributes = params[:hub_feed]
    respond_to do|format|
      if @hub_feed.save
        current_user.has_role!(:editor, @hub_feed)
        current_user.has_role!(:owner, @hub_feed)
        flash[:notice] = 'Created that bookmarking collection.'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Couldn\'t create that bookmarking collection!'
        format.html {render :action => :new}
      end
    end
  end

  def update
    @hub_feed.attributes = params[:hub_feed]
    respond_to do|format|
      if @hub_feed.save
        current_user.has_role!(:editor, @hub_feed)
        flash[:notice] = 'Updated that feed.'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Couldn\'t update that feed!'
        format.html {render :action => :new}
      end
    end
  end

  def edit
  end

  def destroy
    @hub_feed.destroy
    flash[:notice] = 'Removed that feed.'
    redirect_to(hub_path(@hub))
  rescue
    flash[:error] = "Couldn't remove that feed."
    redirect_to(hub_path(@hub))
  end

  private

  def load_hub_feed
    @hub_feed = HubFeed.find_by_id(params[:id])
  end

  def load_hub
    unless @hub_feed.blank?
      @hub = @hub_feed.hub
    else
      @hub = Hub.find(params[:hub_id])
    end
  end

  def prep_resources
  end

  def add_breadcrumbs
    breadcrumbs.add @hub.title, hub_path(@hub)
  end

end
