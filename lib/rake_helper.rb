# frozen_string_literal: true
module RakeHelper
  def add_example_feeds(hub_name, feeds, user_email)
    h = Hub.find_or_initialize_by(title: hub_name)
    u = User.find_by(email: user_email)

    if h.new_record?
      h.save
      u.has_role!(:owner, h)
      u.has_role!(:creator, h)
    end

    feeds.each do |feed|
      begin
        f = Feed.find_or_initialize_by(feed_url: feed)
        puts "Getting: #{feed}"

        if f.valid?
          if f.new_record?
            f.save
            u.has_role!(:owner, f)
            u.has_role!(:creator, f)
          end

          hf = HubFeed.find_or_initialize_by(hub_id: h.id, feed_id: f.id)
          if hf.valid? && hf.new_record?
            hf.save
            u.has_role!(:owner, hf)
            u.has_role!(:creator, hf)
          end
        end

      rescue Exception => e
        puts "Failed on #{feed}, error: #{e.inspect}"
      end
    end
    u.save
  end
end
