Feature: Search by tag
    In order to find items relevant to their interests, users should be able to search by tag.

    @wip
    Scenario: Searching for a simple tag
        Given I am not logged in
        And I am viewing the "Berkman Planet Test Hub" hub
        When I search for "#video"
        Then every result should have the tag "video"

    Scenario: Searching for a tag with a space with quotes
        Given I am not logged in
        And I am viewing the "Berkman Planet Test Hub" hub
        When I search for "#"berkman buzz""
        Then every result should have the tag "berkman buzz"

    Scenario: Searching for a tag with a space with backslashes
        Given I am not logged in
        And I am viewing the "Berkman Planet Test Hub" hub
        When I search for "#berkman\ buzz"
        Then every result should have the tag "berkman buzz"
