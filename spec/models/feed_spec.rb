require 'spec_helper'

describe Feed do
  before :all do
    Feed.create(:feed_url => "http://blogs.law.harvard.edu/djcp/feed/atom/")
  end

  before :each do
    @feed = Feed.new
  end

  context do
    it "has basic attributes", :attributes => true do
      should have_and_belong_to_many(:feed_items)
      should have_many(:feed_retrievals)
      should have_many(:hub_feeds)
      should validate_presence_of(:feed_url)
      should validate_uniqueness_of(:feed_url)

      should ensure_length_of(:title).is_at_most(500.bytes)
      should ensure_length_of(:description).is_at_most(2.kilobytes)
      should ensure_length_of(:guid).is_at_most(1.kilobyte)
      should ensure_length_of(:rights).is_at_most(500.bytes)
      should ensure_length_of(:authors).is_at_most(1.kilobyte)
      should ensure_length_of(:feed_url).is_at_most(1.kilobyte)
      should ensure_length_of(:link).is_at_most(1.kilobyte)
      should ensure_length_of(:generator).is_at_most(500.bytes)
      should ensure_length_of(:flavor).is_at_most(25.bytes)
      should ensure_length_of(:language).is_at_most(25.bytes)

      [:feed_url,:guid,:authors,:generator,:flavor].each do|col|
        should have_db_index(col)
      end

    end

    it "is given invalid feed_urls" do
      @feed.feed_url = 'http://blogs.law.harvard.edu/asdf'
      assert ! @feed.valid?

      @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feasdf3ked'
      assert ! @feed.valid?

      @feed.feed_url = 'htt'
      assert ! @feed.valid?
    end

    it "should follow redirects" do
      @feed.feed_url = 'http://blogs.law.harvard.edu/doc/feed'
      assert @feed.valid?

      sleep 4

      @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed'
      assert @feed.valid?

    end

    it "should work with SSL feeds" do
      @feed.feed_url = 'https://blogs.law.harvard.edu/doc/feed/'
      assert @feed.valid?

      sleep 4

      @feed.feed_url = 'https://blogs.law.harvard.edu/djcp/feed/'
      assert @feed.valid?
    end

    it "should work with redirected SSL feeds" do
      @feed.feed_url = 'https://blogs.law.harvard.edu/doc/feed'
      assert @feed.valid?

      sleep 4

      @feed.feed_url = 'https://blogs.law.harvard.edu/djcp/feed'
      assert @feed.valid?

    end

    it "is given valid feed_urls" do

      @feed.feed_url = 'http://rss.slashdot.org/Slashdot/slashdot'
      assert @feed.valid?

      @feed.feed_url = 'http://feeds.delicious.com/v2/rss/djcp?count=15'
      assert @feed.valid?

      @feed.feed_url = 'http://blogs.law.harvard.edu/doc/feed/'
      assert @feed.valid?

      sleep 4

      @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed/'
      assert @feed.valid?

      sleep 4

      @feed.feed_url = 'http://blogs.law.harvard.edu/corpgov/feed/atom/'
      assert @feed.valid?

    end

  end

end
