Feature: Manage feeds
  In order to add feeds
  a user
  should be able to create a feed.
  
  Scenario: Register new feed
    Given I am on the new feed page
    When I fill in "Title" with "title 1"
    And I fill in "Description" with "description 1"
    And I fill in "Flavor" with "flavor 1"
    And I fill in "Url" with "url 1"
    And I fill in "Feed url" with "feed_url 1"
    And I fill in "Etag" with "etag 1"
    And I press "Create"
    Then I should see "title 1"
    And I should see "description 1"
    And I should see "flavor 1"
    And I should see "url 1"
    And I should see "feed_url 1"
    And I should see "etag 1"

  Scenario: Delete feed
    Given the following feeds:
      |title|description|flavor|url|feed_url|etag|
      |title 1|description 1|flavor 1|url 1|feed_url 1|etag 1|
      |title 2|description 2|flavor 2|url 2|feed_url 2|etag 2|
      |title 3|description 3|flavor 3|url 3|feed_url 3|etag 3|
      |title 4|description 4|flavor 4|url 4|feed_url 4|etag 4|
    When I delete the 3rd feed
    Then I should see the following feeds:
      |Title|Description|Flavor|Url|Feed url|Etag|
      |title 1|description 1|flavor 1|url 1|feed_url 1|etag 1|
      |title 2|description 2|flavor 2|url 2|feed_url 2|etag 2|
      |title 4|description 4|flavor 4|url 4|feed_url 4|etag 4|
