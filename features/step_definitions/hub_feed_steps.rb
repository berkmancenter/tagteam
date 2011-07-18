Given /^the following hub_feeds:$/ do |hub_feeds|
  HubFeed.create!(hub_feeds.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) hub_feed$/ do |pos|
  visit hub_feeds_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following hub_feeds:$/ do |expected_hub_feeds_table|
  expected_hub_feeds_table.diff!(tableish('table tr', 'td,th'))
end
