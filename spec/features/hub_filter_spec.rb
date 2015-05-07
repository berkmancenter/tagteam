require "rails_helper"

shared_examples "a tag filter" do
end

feature "Hub-level tag filtering" do
  #it_behaves_like "a tag filter"

  context "User owns a hub with 10 items" do
    scenario "User creates a new 'add' filter" do
      visit hub_hub_tag_filters_path @hub
      click_link ".add_filter_control"
      fill_in "#new_tag_for_filter", with: "test-tag"
      click_button "Submit"

      expect(page).to have_text "Added that filter"
      visit items_hub_path @hub
      expect(page).to have_text "test-tag", count: 10
    end

    context "At least one item has tag 'test-tag'" do
      scenario "User creates a new 'modify' filter" do
        visit hub_hub_tag_filters_path @hub
        click_link "Modify a tag for every item in this hub"
      end

      scenario "User creates a new 'remove' filter" do
      end
    end

    scenario "User creates a duplicate filter" do
    end

    scenario "User removes an existing 'add' filter" do
    end
    scenario "User removes an existing 'modify' filter" do
    end
    scenario "User removes an existing 'remove' filter" do
    end
    scenario "User removes part of a 'modify' filter chain" do
    end

    context "A filter exists that affects a tag" do
      scenario "User creates a filter that affects the same tag" do
      end
    end

    scenario "User doesn't have hub-level filtering permissions" do
    end

    scenario "User re-sorts existing filters" do
    end

    context "Multiple hubs with the same items exist" do
      context "User has an 'add' filter in one hub" do
        scenario "User sees added tag in only that hub" do
        end
      end
    end
  end
end
