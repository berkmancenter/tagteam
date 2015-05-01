require "rails_helper"

# Only interactions between filter levels are tested here. For in-level
# interactions, look at the level-specific filter specs.

feature "Tag filter interactions" do
  context "Tags from an external feed exist" do
  end

  context "Tags from the bookmarklet exist" do
  end

  context "A hub-level filter exists" do
    scenario "User adds a feed-level filter" do
    end

    scenario "User adds an item-level filter" do
    end

    scenario "User adds a duplicate feed-level filter" do
    end

    scenario "User adds a duplicate item-level filter" do
    end

    context "A feed-level filter exists" do
      scenario "User adds an item-level filter" do
      end
      scenario "User adds a duplicate item-level filter" do
      end
    end
  end

  context "A feed-level filter exists" do
    scenario "User adds an item-level filter" do
    end
  end
end
