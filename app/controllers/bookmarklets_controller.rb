class BookmarkletsController < ApplicationController

  layout 'bookmarklet'

  def add_item

  end

  def add
    logger.warn(params[:bookmarklet].inspect)
    @feed_item = FeedItem.new
    @feed_item.url = params[:feed_item][:url]
    @feed_item.title = params[:feed_item][:title]
    @feed_item.description = params[:feed_item][:description]

  end

end
