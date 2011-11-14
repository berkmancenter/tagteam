class HubsController < ApplicationController
  before_filter :load_hub, :except => [:index, :new, :create]
  before_filter :prep_resources

  access_control do
    allow all, :to => [:index, :show, :feeds, :republished_feeds, :watching, :republishing]
    allow logged_in, :to => [:new, :create]
    allow :owner, :of => :hub, :to => [:edit, :update, :destroy, :add_feed]
    allow :superadmin, :hubadmin
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
        format.json{ render(:json => {:message => 'Added that feed'}) and return }
      else
        format.json{ render(:text => @hub_feed.errors.full_messages.join('<br />'), :status => :not_acceptable) and return }
      end
    end
  end
  
  def feeds
    respond_to do|format|
      format.html{
        if request.xhr?
          render :partial => 'shared/line_items/hub_feed', :collection => @hub.hub_feeds
        else
          render
        end
      }
    end
  end

  def republished_feeds
    respond_to do|format|
      format.html{
        if request.xhr?
          # FIXME
          render :partial => 'shared/line_items/republished_feed_choice', :collection => @hub.republished_feeds
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
    @hubs = Hub.paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def show
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

  def watching
    @hub = Hub.find(params[:id], :include => [:hub_feeds => [:feed => [:feed_items => [:feed_item_tags]]]])
    respond_to do|format|
      format.html{
        render :layout => ! request.xhr? 
      }
    end
  end

  def republishing
    @hub = Hub.find(params[:id], :include => [:accepted_roles => [:users], :republished_feeds => []])
    respond_to do|format|
      format.html{
        render :layout => ! request.xhr? 
      }
    end
  end

  private

  def load_hub
    @hub = Hub.find(params[:id])
    @owners = @hub.owners
  end

  def prep_resources
    @javascripts_extras = ['hubs']
  end

end
