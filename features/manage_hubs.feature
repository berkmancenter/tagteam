Feature: Manage hubs
  In order to manage hubs, users should be able to take various actions on hubs.
  
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

    @wip
  Scenario: An owner can remove a hub
    Given I am the user "foo@bar.com" identified by "foobar22"
    And I am on the new hub page
    When I fill in "Title" with "title 1"
    And I fill in "Description" with "description 1"
    And I fill in "Tag prefix" with "tag_prefix 1"
    And I press "Create"
    Then I should see "title 1"
    And I should see "Delete"
    When I follow "Delete"
    Then I should see "Deleted that hub"

  @allow-rescue @wip
  Scenario: An anonymous user can't remove a hub
    Given I am the user "foo@bar.com" identified by "foobar22"
    And I am on the new hub page
    When I fill in "Title" with "title 1"
    And I fill in "Description" with "description 1"
    And I fill in "Tag prefix" with "tag_prefix 1"
    And I press "Create"
    Then I should see "title 1"
    Given I am not logged in
    When I attempt to delete a hub page
    And I visit the hub I just attempted to delete
		Then I should get a response with an error code of "200"

	@allow-rescue @wip
	Scenario: Can't create a hub if anonymous
    Given I go to the home page
    And I am not logged in
		When I go to the new hub page
		Then I should get a response with an error code of "500"

    @wip
  Scenario: Be able to add a feed to a hub
    Given I am the user "foo@bar.com" identified by "foobar22"
    And a hub I own titled "Test hub fibble foo"
    And I go to the hub detail page
    When I fill in "Add Feed" with "http://blogs.law.harvard.edu/djcp/feed/"
    And I press "Add Feed"
    Then I should see "Daniel Collis-Puro"
    And I should see "Added that feed"


