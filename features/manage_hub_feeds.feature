Feature: Manage hub_feeds
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Register new hub_feed
    Given I am on the new hub_feed page
    When I fill in "Feed" with "feed_id 1"
    And I fill in "Title" with "title 1"
    And I fill in "Description" with "description 1"
    And I press "Create"
    Then I should see "feed_id 1"
    And I should see "title 1"
    And I should see "description 1"

  Scenario: Delete hub_feed
    Given the following hub_feeds:
      |feed_id|title|description|
      |feed_id 1|title 1|description 1|
      |feed_id 2|title 2|description 2|
      |feed_id 3|title 3|description 3|
      |feed_id 4|title 4|description 4|
    When I delete the 3rd hub_feed
    Then I should see the following hub_feeds:
      |Feed|Title|Description|
      |feed_id 1|title 1|description 1|
      |feed_id 2|title 2|description 2|
      |feed_id 4|title 4|description 4|
