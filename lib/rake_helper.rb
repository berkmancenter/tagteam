module RakeHelper
  def add_example_feeds(hub_name, feeds, user_email)
    h = Hub.find_or_create_by_title(:title => hub_name)
    u = User.find_by_email(user_email)

    u.has_role!(:owner, h)
    u.has_role!(:creator, h)

    feeds.each do|feed|
      f = Feed.find_or_initialize_by_feed_url(feed)
      puts "Getting: #{feed}"

      if f.valid?
        f.save
        u.has_role!(:owner, f)
        u.has_role!(:creator, f)

        hf = HubFeed.new
        hf.hub = h
        hf.feed = f

        if hf.valid?
          hf.save
          u.has_role!(:owner, hf)
          u.has_role!(:creator, hf)
        else 
          puts "Hub feed Error: #{hf.errors.inspect}"
        end
      else
        puts "Feed Error: #{f.errors.inspect}"
      end
    end

  end
end
