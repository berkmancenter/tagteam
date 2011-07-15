Feature: Manage hubs
  In order to manage hubs,
  a user
  should be able to create a hub.
  
  @wip
  Scenario: Register new hub
    Given I am the user "foo@bar.com" identified by "foobar22"
    And I am on the new hub page
    When I fill in "Title" with "title 1"
    And I fill in "Description" with "description 1"
    And I fill in "Tag prefix" with "tag_prefix 1"
    And I press "Create"
    Then I should see "title 1"
    And I should see "description 1"
    And I should see "tag_prefix 1"
    And I should see "foo@bar.com"

  Scenario: Delete hub
    Given the following hubs:
      |title|description|tag_prefix|
      |title 1|description 1|tag_prefix 1|
      |title 2|description 2|tag_prefix 2|
      |title 3|description 3|tag_prefix 3|
      |title 4|description 4|tag_prefix 4|
    When I delete the 3rd hub
    Then I should see the following hubs:
      |Title|Description|Tag prefix|
      |title 1|description 1|tag_prefix 1|
      |title 2|description 2|tag_prefix 2|
      |title 4|description 4|tag_prefix 4|
