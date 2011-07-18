Feature: Manage hubs
  In order to manage hubs,
  a user
  should be able to create a hub.
  
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

