class InputSourcesController < ApplicationController
  before_filter :load_input_source, :except => [:new, :create]
  before_filter :load_republished_feed, :only => [:new, :create]

  access_control do
    allow all, :to => [:show]
    allow :owner, :of => :republished_feed, :to => [:new, :create]
    allow :owner, :of => :input_source, :to => [:edit, :update, :destroy]
    allow :superadmin, :input_source_admin
  end


  private

  def load_republished_feed
    republished_feed_id = (params[:input_source].blank?) ? params[:republished_feed_id] : params[:input_source][:republished_feed_id]
    @republished_feed = RepublishedFeed.find(republished_feed_id)
  end

  def load_input_source
    @input_source = InputSource.find(params[:id])
  end

end
