class RepublishedFeedsController < ApplicationController
  before_filter :load_republished_feed, :except => [:index, :new, :create]
  before_filter :prep_resources

  access_control do
    allow all, :to => [:index, :show, :feeds, :rss, :atom]
    allow logged_in, :to => [:new, :create]
    allow :owner, :of => :republished_feed, :to => [:edit, :update, :destroy]
    allow :superadmin, :republished_feed_admin
  end

  def index
  end

  def show
  end

  def new
  end

  def create
  end

  def update
  end

  def edit
  end

  def destroy
  end

  def rss
  end

  def atom
  end

  private

  def load_republished_feed
    @republished_feed = RepublishedFeed.find(params[:id])
  end

  def prep_resources
#    @javascripts_extras = ['republished_feeds']
  end

end
