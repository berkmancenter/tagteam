# A Hub is the base unit of organization for TagTeam. Please see README_FOR_APP for more details on how everything fits together.
class HubsController < ApplicationController
  caches_action :index, :items, :show, :search, :by_date, :retrievals, :bookmark_collections, :meta, :unless => Proc.new{|c| current_user }, :expires_in => Tagteam::Application.config.default_action_cache_time, :cache_path => Proc.new{ 
    Digest::MD5.hexdigest(request.fullpath + "&per_page=" + get_per_page)
  }

  access_control do
    allow all, :to => [:index, :list, :items, :show, :search, :by_date, :retrievals, :item_search, :bookmark_collections, :all_items, :contact, :request_rights, :meta, :home, :about]
    allow logged_in, :to => [:new, :create, :my, :my_bookmark_collections, :background_activity, :tag_controls]
    allow :owner, :of => :hub, :to => [:edit, :update, :destroy, :add_feed, :my_bookmark_collections, :custom_republished_feeds, :community, :add_roles, :remove_roles]
    allow :inputter, :of => :hub, :to => [:add_feed]
    allow :remixer, :of => :hub, :to => [:custom_republished_feeds]
    allow :superadmin
  end

  before_filter :sanitize_params, :only => :index
  before_filter :find_slugged_hub, :only => :show

  SORT_OPTIONS = {
    'title' => lambda { |rel| rel.order('title') },
    'date' => lambda { |rel| rel.order('created_at') },
    'owner' => lambda { |rel| rel.by_first_owner }
  }
  SORT_DIR_OPTIONS = ['asc', 'desc']

  def about
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    render layout: 'tabs'
  end

  def created
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
  end

  def find_slugged_hub
    return unless params[:id]
    @hub = Hub.find params[:id]

    # If an old id or a numeric id was used to find the record, then
    # the request path will not match the hub_path, and we should do
    # a 301 redirect that uses the current friendly id.
    if request.path != hub_path(@hub)
      return redirect_to @hub, :status => :moved_permanently
    end
  end

  def meta
    render :layout => ! request.xhr?
  end

  def list
    @hubs = Hub.paginate(:page => params[:p] || 1, :per_page => 25).order('title ASC')
  end

  def request_rights
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @errors = ''
    if params[:contact][:email].nil? || params[:contact][:email] !~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
      @errors += 'Email address is invalid<br/>'
    end

    if params[:contact][:message].blank?
      @errors += 'Please fill in a message'
    end

    if @errors.blank?
      Contact.request_rights(params,@hub).deliver
      render :text => '' and return
    else
      render :text => @errors, :status => :not_acceptable and return
    end
    
  end

  def contact
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    render layout: request.xhr? ? false : 'tabs'
  end

  def community
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    render layout: request.xhr? ? false : 'tabs'
  end

  def add_roles
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    if ! params[:user_ids].blank? && ! params[:roles].blank?
      params[:user_ids].each do|u|
        user = User.find(u)
        params[:roles].each do|r|
          @hub.accepts_role!(r, user)
        end
      end
    end
    redirect_to request.referer
  end

  def remove_roles
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    # TODO - Refactor this to work in a model-level after trigger, so that rights are properly revoked/reassigned when modified anywhere.
    messages = []
    params[:roles_to_remove] && params[:roles_to_remove].each do|r|
      data = r.split(':')
      user = User.find(data[1])
      if @hub.accepted_roles_by(user).reject{|q| q.name != data[0]}.length > 0
        objects_of_concern = Hub::DELEGATABLE_ROLES_HASH[data[0].to_sym][:objects_of_concern].call(user,@hub)
        if params[:revocation_action] == 'reassign'
          potential_user_to_reassign_to = User.find(params[:reassign_to])
          # could be exploited via URL tampering, so double-check.
          user_to_reassign_to = (@hub.owners.include?(potential_user_to_reassign_to)) ? potential_user_to_reassign_to : @hub.owners.first
          objects_of_concern.each do|obj|
            obj.accepts_no_role!(:owner, user)
            obj.accepts_role!(:owner, user_to_reassign_to)
          end
        else
          objects_of_concern.each do|obj|
            obj.destroy
          end
        end
        @hub.accepts_no_role!(data[0], user)
        messages << "We deleted #{user.email}'s role as a #{Hub::DELEGATABLE_ROLES_HASH[data[0].to_sym][:name]} in this hub."
      end
    end
    flash[:notice] = messages.join(' ')
    redirect_to request.referer
  end

  # A list of feed retrievals for the feeds in this hub, accessible via html, json, and xml.
  def retrievals
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    hub_id = @hub.id
    @feed_retrievals = FeedRetrieval.search(:include => [:feed => {:hub_feeds => [:feed]}]) do
      with(:hub_ids, hub_id)
      order_by('updated_at', :desc)
      paginate :page => params[:page], :per_page => get_per_page
    end

    respond_to do|format|
      format.html{ render layout: request.xhr? ? false : 'tabs' }
      format.json{ render_for_api :default, :json => (@feed_retrievals.blank?) ? [] : @feed_retrievals.results }
      format.xml{ render_for_api :default, :xml => (@feed_retrievals.blank?) ? [] : @feed_retrievals.results }
    end
  end

  # Looks through the currently running resque jobs and returns a json response talking about what's going on.
  def background_activity
    require 'sidekiq/api'
    @output = {:running => []}
    workers = Sidekiq::Workers.new
    workers.collect.each do |process_id, thread_id, work|
      started_at = Time.at(work['run_at'])
      running_seconds = Time.now - started_at
      if running_seconds > 60
        running_for = "#{(running_seconds.round / 60)} minute(s), #{(running_seconds.round % 60)} seconds"
      else
        running_for = "#{running_seconds.round} seconds"
      end
      job = {
        :description => work['payload']['class'].constantize.display_name,
        :since => started_at,
        :running_for => running_for
      }
      @output[:running] << job
    end
    stats = Sidekiq::Stats.new
    @output[:queued] = stats.enqueued

    respond_to do|format|
      format.json{ render :json => @output }
    end
  end

  # A users' bookmark collections, only accessible to logged in users. Accessible as html, json, and xml.
  def bookmark_collections
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @bookmark_collections = HubFeed.bookmark_collections.where(:hub_id => @hub.id).paginate(:page => params[:page], :per_page => get_per_page)
    respond_to do|format|
      format.html{ render layout: request.xhr? ? false : 'tabs' }
      format.json{ render_for_api :default, :json => @bookmark_collections }
      format.xml{ render_for_api :default, :xml => @bookmark_collections }
    end
  end

  # Accessible via html, json, and xml. Pass in the date by appending "/" separated parameters to this action, so: /hubs/1/by_date/2012/03/28. If you put in "00" for the month or day parameter, we'll search for all items form that month or year.
  def by_date
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)

    if params[:month] == '00'
      # Year search
      date = DateTime.parse("#{params[:year]}-01-01")
      start_day = date - 1.second
      end_day = date + 1.year
      breadcrumbs.add date.year, by_date_hub_path(@hub,:year => date.year, :month => '00', :day => '00')
    elsif params[:day] == '00'
      # Month search
      date = DateTime.parse("#{params[:year]}-#{params[:month]}-01")
      start_day = date - 1.second
      end_day = date + 1.month
      breadcrumbs.add date.year, by_date_hub_path(@hub,:year => date.year, :month => '00', :day => '00')
      breadcrumbs.add date.month, by_date_hub_path(@hub,:year => date.year, :month => date.month, :day => '00')
    else
      # Day search
      date = DateTime.parse("#{params[:year]}-#{params[:month]}-#{params[:day]}")
      start_day = date - 1.second
      end_day = date + 1.day
      breadcrumbs.add date.year, by_date_hub_path(@hub,:year => date.year, :month => '00', :day => '00')
      breadcrumbs.add date.month, by_date_hub_path(@hub,:year => date.year, :month => date.month, :day => '00')
      breadcrumbs.add date.day, by_date_hub_path(@hub,:year => date.year, :month => date.month, :day => date.day)
    end
    start_day = start_day - DateTime.now.offset 
    end_day = end_day - DateTime.now.offset 

    hub_id = @hub.id

    @search = FeedItem.search do
      with(:date_published).between(start_day..end_day)
      with :hub_ids, hub_id
      paginate :page => params[:page], :per_page => get_per_page
      order_by(:date_published, :desc)
    end

    @feed_items = @search.results
    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @feed_items }
      format.xml{ render_for_api :default, :xml => @feed_items }
    end
  end

  # Recalculate all tag facets and re-apply all filters for all items in this hub. Only available to users with the "superadmin" privilege.
  def recalc_all_tags
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    Sidekiq::Client.enqueue(RecalcAllItems,@hub.id)
    flash[:notice] = 'Re-rendering all tags. This will take a while.'
    redirect_to request.referer
  end

  def all_items
    items
  end

  # A paginated list of all items in this hub. Available as html, atom, rss, json, and xml. 
  def items
    unless params[:id].blank?
      @hub = Hub.find(params[:id])
      breadcrumbs.add @hub, hub_path(@hub)
      hub_id = @hub.id
    end

    if request.format.to_s.match(/rss|atom/i)
      @search = FeedItem.search(:include => [:feeds, :hub_feeds]) do
        unless hub_id.blank?
          with(:hub_ids, hub_id)
        end
        order_by('date_published', :desc)
        order_by('id', :asc)
        paginate :page => params[:page], :per_page => get_per_page
      end
    else
      @search = FeedItem.search(:select => FeedItem.columns_for_line_item, :include => [:feeds, :hub_feeds]) do
        unless hub_id.blank?
          with(:hub_ids, hub_id)
        end
        order_by('date_published', :desc)
        order_by('id', :asc)
        paginate :page => params[:page], :per_page => get_per_page
      end
    end

    respond_to do |format|
      format.html{ 
        unless @hub.blank?
          @show_auto_discovery_params = items_hub_url(@hub, :format => :rss)
        end
        if params[:view] == 'grid'
          template = 'hubs/items_grid'
        else
          template = 'hubs/items'
        end
        render template, layout: request.xhr? ? false : 'tabs'
      }
      format.rss{ render :template => 'hubs/items.rss' }
      format.atom{ render :template => 'hubs/items.atom' }
      format.json{ render_for_api :default, :json => (@search.blank?) ? [] : @search.results }
      format.xml{ render_for_api :default, :xml => (@search.blank?) ? [] : @search.results }
    end
  end

  def tag_controls
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)

    @tag = ActsAsTaggableOn::Tag.find(params[:tag_id])

    @already_filtered_for_hub = @hub.tag_filtered?(@tag)

    if params[:hub_feed_id].to_i != 0
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @already_filtered_for_hub_feed = @hub_feed.tag_filtered?(@tag)
    end

    if params[:hub_feed_item_id].to_i != 0
      @feed_item = FeedItem.find(params[:hub_feed_item_id], select: FeedItem.columns_for_line_item)
      @already_filtered_for_hub_feed_item = @feed_item.tag_filtered?(@tag)
    end

    respond_to do |format|
      format.html{
        render layout: !request.xhr?
      }
    end
  end

  def add_feed
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @feed = Feed.find_or_initialize_by_feed_url(params[:feed_url])

    if @feed.new_record? 
      if @feed.save
        current_user.has_role!(:owner, @feed)
        current_user.has_role!(:creator, @feed)
      else
        # Not valid.
        respond_to do |format|
          # Tell 'em why.
          format.json{ render(:text => @feed.errors.full_messages.join('<br/>'), :status => :not_acceptable) and return }
          format.html { 
            flash[:error] = 'There was a problem adding that feed.'
            redirect_to hub_hub_feeds_path(@hub) and return
          }
        end
      end
    end

    @hub_feed = HubFeed.new
    @hub_feed.hub = @hub
    @hub_feed.feed = @feed

    if @hub_feed.save
      current_user.has_role!(:owner, @hub_feed)
      current_user.has_role!(:creator, @hub_feed)
      if request.xhr?
        render text: 'Added that feed', layout: false
      else
        flash[:notice] = 'Added that feed.'
        redirect_to hub_hub_feeds_path(@hub)
      end
    else
      if request.xhr?
        render(:text => @hub_feed.errors.full_messages.join('<br />'), :status => :not_acceptable)
      else
        flash[:error] = 'There was a problem adding that feed.'
        redirect_to hub_hub_feeds_path(@hub)
      end
    end
  end

  # A list of all republished feeds(aka remixed feeds) that can be added to for the current user.
  def custom_republished_feeds
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @republished_feeds =  RepublishedFeed.select('DISTINCT republished_feeds.*').joins(:accepted_roles => [:users]).where(['roles.name = ? and roles.authorizable_type = ? and roles_users.user_id = ? and hub_id = ?','owner','RepublishedFeed', ((current_user.blank?) ? nil : current_user.id), @hub.id ]).order('updated_at')
 
    respond_to do|format|
      format.html{
        if request.xhr?
           render :layout => false 
        else
          render
        end
      }
    end
  end

  def home
    unless current_user.blank?
      @my_hubs = current_user.my(Hub)
    end
    @hubs = Hub.paginate(:page => params[:page], :per_page => 5 ).order('title ASC') #get_per_page)
    respond_to do|format|
      format.html{ render :layout => ! request.xhr? }
      format.json{ render_for_api :default, :json => @hubs }
      format.xml{ render_for_api :default, :xml => @hubs }
    end
  end

  # All hubs, as html, json, or xml.
  def index
    breadcrumbs.add 'All hubs', hubs_path
    sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : SORT_OPTIONS.keys.first
    order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first
    @hubs = SORT_OPTIONS[sort].call(Hub.paginate(:page => params[:page], :per_page => 5 ))
    @hubs = @hubs.reverse_order if order == 'desc'
    respond_to do|format|
      format.html{ render layout: request.xhr? ? false : 'tabs' }
      format.json{ render_for_api :default, :json => @hubs }
      format.xml{ render_for_api :default, :xml => @hubs }
    end
  end

  # Available as html, json, or xml.
  def show
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @show_auto_discovery_params = items_hub_url(@hub, :format => :rss)
    redirect_to items_hub_path(@hub)
    
    #respond_to do|format|
    #  format.html{ render :layout => ! request.xhr? }
    #  format.json{ render_for_api :default, :json => @hub }
    #  format.xml{ render_for_api :default, :xml => @hub }
    #end
  end

  def new
    @hub = Hub.new
  end

  # A list of the current users' hubs, used mostly by the bookmarklet.
  def my
    @hubs = current_user.my(Hub)
    breadcrumbs.add 'My hubs', my_hubs_path
    respond_to do |format|
      format.html do
        sort = SORT_OPTIONS.keys.include?(params[:sort]) ? params[:sort] : SORT_OPTIONS.keys.first
        order = SORT_DIR_OPTIONS.include?(params[:order]) ? params[:order] : SORT_DIR_OPTIONS.first
        @hubs = SORT_OPTIONS[sort].call(Hub.where(id: @hubs.map(&:id)).paginate(:page => params[:page], :per_page => 5 ))
        @hubs = @hubs.reverse_order if order == 'desc'
        render layout: request.xhr? ? false : 'tabs'
      end
      format.json{ render_for_api :default, :json => @hubs }
      format.xml{ render_for_api :default, :xml => @hubs }
    end
  end

  # A list of the current users' bookmark collections for a specific hub, used mostly by the bookmarklet.
  def my_bookmark_collections
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @bookmark_collections = current_user.my_bookmarking_bookmark_collections_in(@hub)
    respond_to do |format|
      format.json{ render_for_api :bookmarklet_choices, :json => @bookmark_collections }
      format.xml{ render_for_api :bookmarklet_choices, :xml => @bookmark_collections }
    end
  end

  def create
    @hub = Hub.new
    @hub.attributes = params[:hub]
    respond_to do|format|
      if @hub.save
        current_user.has_role!(:owner, @hub)
        current_user.has_role!(:creator, @hub)
        format.html {
          if session[:redirect_after].nil?
            redirect_to hub_path(@hub)
          else
            flash[:notice] = 'Added that Hub.'
            redirect_path = session[:redirect_after]
            session[:redirect_after] = nil
            redirect_to redirect_path
          end
        }
      else
        flash[:error] = 'Could not add that Hub'
        format.html {render :action => :new}
      end
    end
  end

  def edit
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
  end

  def update
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @hub.attributes = params[:hub]
    respond_to do|format|
      if @hub.save
        current_user.has_role!(:editor, @hub)
        flash[:notice] = 'Updated!'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Couldn\'t update!'
        format.html {render :action => :new}
      end
    end
  end

  def destroy
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    @hub.destroy
    flash[:notice] = 'Deleted that hub'
    respond_to do|format|
      format.html{
        redirect_to :back
      }
    end
  end

  # Search results are available as html, json, or xml. 
  def item_search
    @hub = Hub.find(params[:id])
    breadcrumbs.add @hub, hub_path(@hub)
    breadcrumbs.add "Search", request.url
 
    hub_id = @hub.id
    tagging_key = @hub.tagging_key

    @search = FeedItem.search do
      with :hub_ids, hub_id
      paginate :page => params[:page], :per_page => get_per_page
      order_by(:date_published, :desc)
      unless params[:q].blank?
          fulltext params[:q]
          adjust_solr_params do |params|
              params[:q].gsub! '#', "tag_contexts_sm:#{tagging_key}-"
          end
      end
    end

    unless params[:q].blank?
        params[:q].gsub! "tag_contexts_sm:#{@hub.tagging_key}-", '#'
    end

    respond_to do|format|
      format.html{ render layout: request.xhr? ? false : 'tabs' }
      format.json{ render_for_api :default, :json => (@search.blank?) ? [] : @search.results }
      format.xml{ render_for_api :default, :xml => (@search.blank?) ? [] : @search.results }
    end
  end

  def search
    @search = Hub.search do
      paginate :page => params[:page], :per_page => get_per_page
      unless params[:q].blank?
          fulltext params[:q]
      end
    end

    respond_to do|format|
      format.html{ render layout: request.xhr? ? false : 'tabs' }
      format.json{ render :json => @search }
    end

  end

  private

  def sanitize_params
      params[:page] = params[:page] =~ /^\d*$/ ? params[:page] : 1
  end

end
