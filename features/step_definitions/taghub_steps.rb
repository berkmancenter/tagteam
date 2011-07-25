Given /^I am not logged in$/ do
	# Nothing.
end

Then /^I should get a response with an error code of "([^"]*)"$/ do |status_code|
	page.driver.status_code.should == status_code.to_i
end

