require "rails_helper"

feature "Feed-level tag filtering" do
  it_behaves_like "a tag filter"

  scenario "User doesn't have feed-level filtering permissions" do
  end
end
