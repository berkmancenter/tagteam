Given /^the following hubs:$/ do |hubs|
  Hub.create!(hubs.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) hub$/ do |pos|
  visit hubs_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following hubs:$/ do |expected_hubs_table|
  expected_hubs_table.diff!(tableish('table tr', 'td,th'))
end

Given "I am the user \"$email\" identified by \"$password\"" do |email,password|
  @user = User.new(:email => email, :password => password, :password_confirmation => password)
  @user.save
  visit new_user_session_path
  fill_in('Email', :with => email)
  fill_in('Password', :with => password)
  click_button('Sign in')
end

