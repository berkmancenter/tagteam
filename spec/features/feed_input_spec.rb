require 'rails_helper'

feature "Hub input feed management" do
  scenario "User adds an input feed" do
    # items get added with tags
  end

  scenario "User removes an input feed" do
    # items do not get removed
    # taggings with feed as owner get put where? still need a global context
    # feed still exists, but isn't updated and doesn't show in any hubs?
  end

  context "Multiple hubs exist with same input feeds" do
    scenario "User looks at the tags in each hub" do
    end
  end
end
