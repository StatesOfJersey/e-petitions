Feature: Freya searches petitions by parish
  In order to see what petitions are relevant to other people in my parish
  As Freya, a member of the general public
  I want to use my postcode to find my parish and see petitions with signatures from people who also live in it

  Background:
    Given a parish "Saint Martin" is found by postcode "JE3 6AA"
    And a parish "Grouville" is found by postcode "JE9 1AA"
    And an open petition "Save the monkeys" with some signatures
    And an open petition "Restore vintage diggers" with some signatures
    And an open petition "Build more quirky theme parks" with some signatures
    And a closed petition "What about other primates?" with some signatures
    And a resident in "Grouville" supports "Restore vintage diggers"
    And few residents in "Saint Martin" support "Save the monkeys"
    And some residents in "Saint Martin" support "Build more quirky theme parks"
    And many residents in "Grouville" support "Build more quirky theme parks"
    And a resident in "Saint Martin" supports "What about other primates?"

  Scenario: Searching for local petitions
    Given I am on the home page
    When I search for petitions local to me in "JE3 6AA"
    Then I should be on the local petitions results page
    And the markup should be valid
    And I should see "Petitions in Saint Martin" in the browser page title
    And I should see "Popular open petitions in the parish of Saint Martin"
    And I should see a link to view all local petitions
    And I should see that my fellow parish residents support "Save the monkeys"
    And I should see that my fellow parish residents support "Build more quirky theme parks"
    But I should not see that my fellow parish residents support "What about other primates?"
    And I should not see that my fellow parish residents support "Restore vintage diggers"
    And the petitions I see should be ordered by my fellow parish residents level of support
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    And I should see "Popular petitions in the parish of Saint Martin"
    And I should see a link to view open local petitions
    And I should see that my fellow parish residents support "What about other primates?"
    And I should see that closed petitions are identified
    And the petitions I see should be ordered by my fellow parish residents level of support

  Scenario: Downloading the JSON data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "JE3 6AA"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the JSON data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "JE3 6AA"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all local petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for open local petitions
    Given I am on the home page
    When I search for petitions local to me in "JE3 6AA"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "open-popular-petitions-in-saint-martin.csv"

  Scenario: Downloading the CSV data for all local petitions
    Given I am on the home page
    When I search for petitions local to me in "JE3 6AA"
    Then I should be on the local petitions results page
    And the markup should be valid
    When I click the view all local petitions
    Then I should be on the all local petitions results page
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-popular-petitions-in-saint-martin.csv"

  Scenario: Searching for local petitions when the api is down
    Given the parish api is down
    And I am on the home page
    When I search for petitions local to me in "JE3 6AA"
    Then the markup should be valid
    But I should see an explanation that my parish couldn't be found

  Scenario: Searching for local petitions when the no-one in my parish is engaged
    Given a parish "Saint Mary" is found by postcode "JE3 3AA"
    And I am on the home page
    When I search for petitions local to me in "JE3 3AA"
    Then the markup should be valid
    But I should see an explanation that there are no petitions popular in my parish
