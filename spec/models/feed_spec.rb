require 'spec_helper'

describe Feed do
  before :each do
    @feed = Feed.new
  end

  context do
    it "is given invalid feed_urls" do
      @feed.feed_url = 'http://blogs.law.harvard.edu/asdf'
      assert ! @feed.valid?

      @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed'
      assert ! @feed.valid?

      @feed.feed_url = 'htt'
      assert ! @feed.valid?
    end

    it "is given valid feed_urls" do

      @feed.feed_url = 'http://rss.slashdot.org/Slashdot/slashdot'
      assert @feed.valid?

      @feed.feed_url = 'http://feeds.delicious.com/v2/rss/djcp?count=15'
      assert @feed.valid?

      @feed.feed_url = 'http://blogs.law.harvard.edu/doc/feed/'
      assert @feed.valid?

      sleep 2

      @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed/'
      assert @feed.valid?

      sleep 2

      @feed.feed_url = 'http://blogs.law.harvard.edu/corpgov/feed/atom/'
      assert @feed.valid?

    end

  end

end
