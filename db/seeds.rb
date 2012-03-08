# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# 

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

