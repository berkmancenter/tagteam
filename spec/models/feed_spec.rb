require 'rails_helper'

describe Feed do
  it "owns all taggings that come in from its URL"

  context 'a feed exists' do
    before(:each) do
      @feed = create(:feed)
      subject { @feed }
    end

    describe '#valid?' do
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
end
