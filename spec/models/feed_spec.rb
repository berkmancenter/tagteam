require 'spec_helper'

describe Feed do
	before :each do
		@feed = Feed.new
	end

	context do
		it "has basic attributes", :offline => true do
      should have_many(:feed_items)
			should have_many(:feed_retrievals) 
			should have_and_belong_to_many(:hub_feeds) 
			should validate_presence_of(:title) 
			should validate_presence_of(:feed_url) 
			should validate_uniqueness_of(:feed_url)

#			it { should respond_to(:move_higher) }
#			it { should respond_to(:move_lower) }

			should have_db_index(:feed_url)

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

			sleep 2

			@feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed'
			assert @feed.valid?

		end

		it "should work with SSL feeds" do
			@feed.feed_url = 'https://blogs.law.harvard.edu/doc/feed/'
			assert @feed.valid?

			sleep 2

			@feed.feed_url = 'https://blogs.law.harvard.edu/djcp/feed/'
			assert @feed.valid?
		end

		it "should work with redirected SSL feeds" do
			@feed.feed_url = 'https://blogs.law.harvard.edu/doc/feed'
			assert @feed.valid?

			sleep 2

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

			sleep 2

			@feed.feed_url = 'http://blogs.law.harvard.edu/djcp/feed/'
			assert @feed.valid?

			sleep 2

			@feed.feed_url = 'http://blogs.law.harvard.edu/corpgov/feed/atom/'
			assert @feed.valid?

		end

	end

end
