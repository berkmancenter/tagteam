Given /^the following feeds:$/ do |feeds|
  Feed.create!(feeds.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) feed$/ do |pos|
  visit feeds_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following feeds:$/ do |expected_feeds_table|
  expected_feeds_table.diff!(tableish('table tr', 'td,th'))
end
