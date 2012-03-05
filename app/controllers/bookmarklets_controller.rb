class BookmarkletsController < ApplicationController

  layout 'bookmarklet'

  def add_item

  end

  def add
    logger.warn(params[:bookmarklet].inspect)

  end

end
