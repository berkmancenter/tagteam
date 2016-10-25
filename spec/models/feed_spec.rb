require 'rails_helper'

describe Feed, needs_review: true do
  it "owns all taggings that come in from its URL"

  context 'a feed exists' do
    before(:each) do
      @feed = create(:feed)
      subject { @feed }
    end

    describe '#valid?' do
      it "is given invalid feed_urls" do
        pending("Needs to be fixed")
        #need to create a new feed not change the existing feed_url
        @feed.feed_url = 'http://blogs.law.harvard.edu/asdf'
        expect(@feed).not_to be_valid

        @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feasdf3ked'
        expect(@feed).not_to be_valid

        @feed.feed_url = 'htt'
        expect(@feed).not_to be_valid
      end

      it "should follow redirects" do
        skip("Needs to be fixed")
        @feed.feed_url = 'http://blogs.law.harvard.edu/doc/feed'
        expect(@feed).to be_valid

        sleep 4

        @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed'
        expect(@feed).to be_valid
      end

      it "should work with SSL feeds" do
        skip("Needs to be fixed")
        @feed.feed_url = 'https://blogs.law.harvard.edu/doc/feed/'
        expect(@feed).to be_valid

        sleep 4

        @feed.feed_url = 'https://blogs.law.harvard.edu/djcp/feed/'
        expect(@feed).to be_valid
      end

      it "should work with redirected SSL feeds" do
        skip("Needs to be fixed")
        @feed.feed_url = 'https://blogs.law.harvard.edu/doc/feed'
        expect(@feed).to be_valid

        sleep 4

        @feed.feed_url = 'https://blogs.law.harvard.edu/djcp/feed'
        expect(@feed).to be_valid
      end

      it "is given valid feed_urls" do
        skip("Needs to be fixed")

        @feed.feed_url = 'http://rss.slashdot.org/Slashdot/slashdot'
        expect(@feed).to be_valid

        @feed.feed_url = 'http://feeds.delicious.com/v2/rss/djcp?count=15'
        expect(@feed).to be_valid

        @feed.feed_url = 'http://blogs.law.harvard.edu/doc/feed/'
        expect(@feed).to be_valid

        sleep 4

        @feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed/'
        expect(@feed).to be_valid

        sleep 4

        @feed.feed_url = 'http://blogs.law.harvard.edu/corpgov/feed/atom/'
        expect(@feed).to be_valid
      end
    end
  end
end
