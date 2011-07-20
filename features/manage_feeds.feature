Feature: Manage feeds
  In order to add feeds
  a user
  should be able to create a feed.
  
	@wip
  Scenario: Register new feed
    Given I am the user "foo@bar.com" identified by "foobar22"
    And I am on the new feed page
    When I fill in "Feed url" with "http://blogs.law.harvard.edu/djcp/feed/"
    And I press "Create"
    Then I should see "Dan Collis-Puro"

