class HubsController < ApplicationController
  before_filter :load_hub, :except => [:index, :new, :create]
  before_filter :add_breadcrumb

  access_control do
    allow all, :to => [:index, :items, :show, :custom_republished_feeds, :tag_controls, :search, :by_date, :retrievals, :item_search]
    allow logged_in, :to => [:new, :create]
    allow :owner, :of => :hub, :to => [:edit, :update, :destroy, :add_feed]
    allow :superadmin, :hubadmin
  end

  def retrievals
    hub_id = @hub.id
    @feed_retrievals = FeedRetrieval.search(:include => [:feed => {:hub_feeds => [:feed]}]) do
      with(:hub_ids, hub_id)
      order_by('updated_at', :desc)
      paginate :page => params[:page], :per_page => get_per_page
    end
    @feed_retrievals.execute!
    logger.warn(@feed_retrievals.inspect)
    render :layout => ! request.xhr?
  end

  def by_date
    # TODO - should just use solr, this code works and performs fine but is odd because it predates the integration of the 
    # solr search engine.
    params[:date] = (params[:date].blank?) ? Time.now.strftime('%Y-%m-%d') : params[:date]
    dates = params[:date].split(/\D/).collect{|d| d.to_i}
    if dates.length > 0
      breadcrumbs.add dates[0], by_date_hub_path(@hub,:date => dates[0])
    end
    if dates.length > 1
      breadcrumbs.add dates[1], by_date_hub_path(@hub,:date => "#{dates[0]}/#{dates[1]}")
    end
    if dates.length > 2
      breadcrumbs.add dates[2], by_date_hub_path(@hub,:date => "#{dates[0]}/#{dates[1]}/#{dates[2]}")
    end

    conditions = [
      'extract(year from date_published) = ?',
      ((dates[1].blank?) ? nil : 'extract(month from date_published) = ?'),
      ((dates[2].blank?) ? nil : 'extract(day from date_published) = ?')
    ].compact

    parameters = [
      dates[0],
      ((dates[1].blank?) ? nil : dates[1]),
      ((dates[2].blank?) ? nil : dates[2])
    ].compact

    @feed_items = FeedItem.paginate(:select => FeedItem.columns_for_line_item, :conditions => [conditions.join(' AND '), parameters].flatten, :order => 'date_published desc', :page => params[:page], :per_page => get_per_page)
    render :layout => ! request.xhr?
  end

  def recalc_all_tags
    Resque.enqueue(RecalcAllItems,@hub.id)
    flash[:notice] = 'Re-rendering all tags. This will take a while.'
    redirect_to hub_path(@hub)
  end

  def items
    @show_auto_discovery_params = items_hub_url(@hub, :format => :rss)
    hub_id = @hub.id

    if request.format.to_s.match(/rss|atom/i)
      @search = FeedItem.search(:include => [:feeds, :hub_feeds]) do
        with(:hub_ids, hub_id)
        order_by('last_updated', :desc)
        paginate :page => params[:page], :per_page => get_per_page
      end
    else
      @search = FeedItem.search(:select => FeedItem.columns_for_line_item, :include => [:feeds, :hub_feeds]) do
        with(:hub_ids, hub_id)
        order_by('last_updated', :desc)
        paginate :page => params[:page], :per_page => get_per_page
      end
    end

    respond_to do |format|
      format.html{ render :layout => ! request.xhr? }
      format.rss{ }
      format.atom{ }
    end
  end

  def tag_controls

    @already_filtered_for_hub = HubTagFilter.where(:hub_id => @hub.id).includes(:filter).collect{|htf| htf.filter.tag_id == params[:tag_id].to_i}.flatten.include?(true)

    if params[:hub_feed_id].to_i != 0
      @hub_feed = HubFeed.find(params[:hub_feed_id])
      @already_filtered_for_hub_feed = HubFeedTagFilter.where(:hub_feed_id => params[:hub_feed_id].to_i).includes(:filter).collect{|hftf| hftf.filter.tag_id == params[:tag_id].to_i}.flatten.include?(true)
    end

    if params[:hub_feed_item_id].to_i != 0
      @feed_item = FeedItem.find(params[:hub_feed_item_id], :select => FeedItem.columns_for_line_item)
      @already_filtered_for_hub_feed_item = HubFeedItemTagFilter.where(:feed_item_id => params[:hub_feed_item_id].to_i).includes(:filter).collect{|hfitf| hfitf.filter.tag_id == params[:tag_id].to_i}.flatten.include?(true)
    end

    @tag = ActsAsTaggableOn::Tag.find(params[:tag_id])
    respond_to do|format|
      format.html{
        render :layout => ! request.xhr?
      }
    end
  end

  def add_feed
    @feed = Feed.find_or_initialize_by_feed_url(params[:feed_url])

    if @feed.new_record? 
      if @feed.save
        current_user.has_role!(:owner, @feed)
        current_user.has_role!(:creator, @feed)
      else
        # Not valid.
        respond_to do |format|
          # Tell 'em why.
          logger.warn(format.inspect)
          format.json{ render(:text => @feed.errors.full_messages.join('<br/>'), :status => :not_acceptable) and return }
        end
      end
    end

    @hub_feed = HubFeed.new
    @hub_feed.hub = @hub
    @hub_feed.feed = @feed

    respond_to do |format|
      if @hub_feed.save
        current_user.has_role!(:owner, @hub_feed)
        current_user.has_role!(:creator, @hub_feed)
        format.html{ 
          render :text => 'Added that feed'
        }
      else
        format.html{ 
          render(:text => @hub_feed.errors.full_messages.join('<br />'), :status => :not_acceptable)
        }
      end
    end
  end

  def custom_republished_feeds
    @republished_feeds =  RepublishedFeed.select('DISTINCT republished_feeds.*').joins(:accepted_roles => [:users]).where(['roles.name = ? and roles.authorizable_type = ? and roles_users.user_id = ? and hub_id = ?','owner','RepublishedFeed', ((current_user.blank?) ? nil : current_user.id), @hub.id ]).order('updated_at')
 
    respond_to do|format|
      format.html{
        if request.xhr?
          unless @republished_feeds.empty?
            render :partial => 'shared/line_items/republished_feed_choice', :collection => @republished_feeds
          else 
            render :text => 'None yet. You should create a new republished feed from the "publishing" tab on the hub page.'
          end
        else
          render
        end
      }
    end
  end

  def index
    unless current_user.blank?
      @my_hubs = current_user.my(Hub)
    end
    @hubs = Hub.paginate(:page => params[:page], :per_page => get_per_page)
  end

  def show
    @show_auto_discovery_params = items_hub_url(@hub, :format => :rss)
  end

  def new
    @hub = Hub.new
  end

  def create
    @hub = Hub.new
    @hub.attributes = params[:hub]
    respond_to do|format|
      if @hub.save
        current_user.has_role!(:owner, @hub)
        current_user.has_role!(:creator, @hub)
        flash[:notice] = 'Added that Hub.'
        format.html {redirect_to hub_path(@hub)}
      else
        flash[:error] = 'Could not add that Hub'
        format.html {render :action => :new}
      end
    end
  end

  def edit
  end

  def update
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
    @hub.destroy
    flash[:notice] = 'Deleted that hub'
    respond_to do|format|
      format.html{
        redirect_to :action => :index
      }
    end
  end

  def item_search

    include_tags = ActsAsTaggableOn::Tag.find(:all, :conditions => {:name => params[:include_tags].split(',').collect{|t| t.downcase.strip}.uniq.compact.reject{|t| t == ''}})
    exclude_tags = ActsAsTaggableOn::Tag.find(:all, :conditions => {:name => params[:exclude_tags].split(',').collect{|t| t.downcase.strip}.uniq.compact.reject{|t| t == ''}})

    @search = FeedItem.search
    hub_id = @hub.id

    hub_context = @hub.tagging_key

    @search.build do
      with :hub_ids, hub_id
      unless params[:q].blank?
        fulltext params[:q]
      end
      unless include_tags.blank?
        any_of do
          with :tag_contexts, include_tags.collect{|it| %Q|#{hub_context}-#{it.id}|}
        end
      end
      unless exclude_tags.blank?
        any_of do
          without :tag_contexts, exclude_tags.collect{|it| %Q|#{hub_context}-#{it.id}|}
        end
      end
      paginate :page => params[:page], :per_page => get_per_page
    end

    @search.execute!
    respond_to do|format|
      format.html{
        render :layout => ! request.xhr?
      }
      format.json{ render :json => @search }
    end
  end

  def search
    unless params[:q].blank?
      @search = Sunspot.new_search ((params[:search_in].blank?) ? [HubFeed,FeedItem,ActsAsTaggableOn::Tag] : params[:search_in].collect{|si| si.constantize})
      hub_id = @hub.id
      @search.build do
        fulltext params[:q]
        with :hub_ids, hub_id
        paginate :page => params[:page], :per_page => get_per_page
      end

      @search.execute!
    end

    if ! params[:include_tags].blank?
      include_tags = ActsAsTaggableOn::Tag.find(:all, :conditions => {:name => params[:include_tags].split(',').collect{|t| t.downcase.strip}.uniq.compact.reject{|t| t == ''}})
    end

    if ! include_tags.blank? 
      @search = FeedItem.search(:select => FeedItem.columns_for_line_item, :include => [:tags, :taggings, :feeds, :hub_feeds])
      hub_context = @hub.tagging_key
      exclude_tags = ActsAsTaggableOn::Tag.find(:all, :conditions => {:name => params[:exclude_tags].split(',').collect{|t| t.downcase.strip}.uniq.compact.reject{|t| t == ''}})

      @search.build do
        any_of do
          with :tag_contexts, include_tags.collect{|it| %Q|#{hub_context}-#{it.id}|}
        end
        unless exclude_tags.blank?
          any_of do
            without :tag_contexts, exclude_tags.collect{|it| %Q|#{hub_context}-#{it.id}|}
          end
        end
        paginate :page => params[:page], :per_page => get_per_page
      end

      @search.execute!
    end

    respond_to do|format|
      format.html{
        render :layout => ! request.xhr?
      }
      format.json{ render :json => @search }
    end

  end

  private

  def load_hub
    @hub = Hub.find(params[:id])
    @owners = @hub.owners
    @is_owner = @owners.include?(current_user)
  end

  def add_breadcrumb
    breadcrumbs.add @hub, hub_path(@hub)
  end

end
