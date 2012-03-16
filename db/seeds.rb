# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# 

require 'digest/md5'

Documentation.create(
  :match_key => 'hub_about',
  :title => 'About a hub',
  :description => %Q|

  <p><strong>A "hub"</strong> collects a number of feeds, feed items and republished feeds together into one organized "hub" of information.</p>

  <p>A hub contains many <strong>watched feeds</strong> (look at the "watching" tab) that serve as input sources of feed items.  These watched feeds are downloaded and parsed for title, content, tags, and other metadata. These feed items serve as the basic unit of information in a tagteam hub.</p>

  <p>A hub also contains <strong>republished feeds</strong>, which are remixes of feeds, feed items and tags. Watched feeds serve as the inputs for republished feeds.</p>

  <p><strong>Filters</strong> 

  |,
  :lang => 'en'
)

shared_key_file = "#{Rails.root}/config/initializers/tagteam_shared_key.rb"
unless File.exists?(shared_key_file)
  f = File.new(shared_key_file,'w',0740)
  f.write("SHARED_KEY_FOR_TASKS='#{Digest::MD5.hexdigest(Time.now.to_s + rand(100000).to_s)}'")
  f.close
end
