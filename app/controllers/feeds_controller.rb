class FeedsController < ApplicationController
  before_filter :load_feed, :except => [:index, :new, :create, :check_feed]
	before_filter :prep_resources

	access_control do
		allow all, :to => [:index, :show]
		allow :superadmin, :hubadmin
		allow logged_in
	end

  def index
  end

  def show
  end

  def new
		@feed = Feed.new
  end

	def check_feed
		feed = Feed.new
		feed.feed_url = params[:feed_url]
		if feed.valid?
			rfeed = feed.raw_feed
			respond_to do |format|
				format.json{
					render :json => {:entries => rfeed.entries, :title => rfeed.title, :description => rfeed.description, :url => rfeed.url}
				}
			end
		else
			render :text => "Not a valid feed. Please try again.", :status => :not_acceptable
		end
	end

  def create
    @feed = Feed.new
    @feed.feed_url = params[:feed][:feed_url]
    respond_to do|format|
      if @feed.save
        current_user.has_role!(:owner, @feed)
        current_user.has_role!(:creator, @feed)
        flash[:notice] = 'Added that feed.'
        format.html {render :action => :show}
      else
        flash[:error] = 'Could not add that feed'
        format.html {render :action => :new}
      end
    end
  end

  def update
  end

  def edit
  end

  def destroy
  end

  private

  def load_feed
    @feed = Feed.find(params[:id])
  end

	def prep_resources
		@javascripts_extras = ['feeds']
	end


end
