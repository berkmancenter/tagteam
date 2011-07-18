class FeedsController < ApplicationController
  before_filter :load_feed, :except => [:index, :new, :create]

  def index
  end

  def show
  end

  def new
		@feed = Feed.new
  end

  def create
    @feed = Feed.new
    @feed.attributes = params[:feed]
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


end
