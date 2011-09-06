require 'spec_helper'

describe HubFeed do

  before(:all) do
    @hub_feed = HubFeed.new
  end

  it 'should have some attributes' do
    @hub_feed.should belong_to :hub
    @hub_feed.should belong_to :feed
    @hub_feed.should respond_to :title
    @hub_feed.should respond_to :description
    @hub_feed.should have_db_index :hub_id
    @hub_feed.should have_db_index :feed_id
  end

end
