class FeedItemsController < ApplicationController
  before_filter :load_feed_item, :except => [:index, :by_date]
  before_filter :add_breadcrumbs, :except => [:index, :by_date]

  access_control do
    allow all
  end

  def index
    @feed_items = FeedItem.paginate(:order => 'updated_at desc', :page => params[:page], :per_page => params[:per_page])
  end

  def show
  end

  def by_date
    date = (params[:date].blank?) ? Time.now.strftime('%Y-%m-%d') : params[:date]
    dates = date.split(/\D/)
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

    @feed_items = FeedItem.paginate(:conditions => [conditions.join(' AND '), parameters].flatten, :order => 'date_published desc', :page => params[:page], :per_page => params[:per_page])
  end

  private

  def load_feed_item
    @feed_item = FeedItem.find(params[:id])
  end

  def add_breadcrumbs

    hub_feed = @feed_item.feeds.first.hub_feeds.first
    unless hub_feed.blank?
      breadcrumbs.add hub_feed.to_s, hub_feed_path(hub_feed) 
    end
  end

end
