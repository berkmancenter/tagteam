Given /^I am not logged in$/ do
  if page.has_content?('log out')
    click_link('log out')
  end
end

Then /^I should get a response with an error code of "([^"]*)"$/ do |status_code|
	page.driver.status_code.should == status_code.to_i
end

Given /^I attempt to delete a hub page$/ do
  @hub = Hub.first
  delete(hub_path(@hub))
end

When /^I visit the hub I just attempted to delete$/ do
  visit(hub_path(@hub))
end

