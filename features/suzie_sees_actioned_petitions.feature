Feature: Suzie sees actioned petitions
  In order to make the site more engaging for browsing
  As Suzie the signer
  I want to see counts and links to petitions that have been actioned

  Scenario: There are no actioned petitions
    Given I am on the home page
    Then I should not see the actioned petitions totals section
    But I should see an empty Ministers response threshold section
    And I should see an empty debate threshold section

  Scenario: There are petitions with a response from Ministers
    Given there are 2 petitions with a Ministers response
    And I am on the home page
    Then I should see a total showing 2 petitions with a Ministers response
    And I should see 2 petitions counted in the response threshold section
    And I should see 2 petitions listed in the response threshold section
    And I should see an empty debate threshold section

  Scenario: There are petitions debated in states assembly
    Given there are 3 petitions debated in states assembly
    And I am on the home page
    Then I should see a total showing 3 petitions debated in states assembly
    And I should see an empty Ministers response threshold section
    And I should see 3 petitions counted in the debate threshold section
    And I should see 3 petitions listed in the debate threshold section

  Scenario: There are petitions with a response from Ministers and petitions debated in states assembly
    Given there are 5 petitions with a Ministers response
    And there are 2 petitions debated in states assembly
    And I am on the home page
    Then I should see a total showing 5 petitions with a Ministers response
    And I should see a total showing 2 petitions debated in states assembly
    And I should see 5 petitions counted in the response threshold section
    And I should see 3 petitions listed in the response threshold section
    And I should see 2 petitions counted in the debate threshold section
    And I should see 2 petitions listed in the debate threshold section

  Scenario: There are petitions debated in states assembly with video, transcript and debate pack urls
    Given there is 1 petition debated in states assembly with a transcript url
    And there is 1 petition debated in states assembly with both video and transcript urls
    And there is 1 petition debated in states assembly with all debate outcome urls
    And I am on the home page
    Then I should see 2 debated petition video links
    And I should see 3 debated petition transcript links
    And I should see 1 debated petition debate pack links
    And I should see 3 petitions counted in the debate threshold section
    And I should see 3 petitions listed in the debate threshold section

  Scenario: There was a petition debated without any debate outcome
    Given a petition "Free the wombles" has been debated yesterday
    And a petition "Ban Badger Baiting" has been debated 12 days ago
    And I am on the home page
    Then I should see "Ban Badger Baiting" in the debate threshold section
    And I should not see "Free the wombles" in the debate threshold section

  Scenario: There was a petition responded to but has since been rejected
    Given a rejected petition "Free Uncle Bulgaria" exists and has received a Ministers response 15 days ago
    And a petition "Ban Badger Baiting" exists and has received a Ministers response 10 days ago
    And I am on the home page
    Then I should see "Ban Badger Baiting" in the response threshold section
    And I should not see "Free Uncle Bulgaria" in the response threshold section

  Scenario: There was a petition debated but has since been rejected
    Given a rejected petition "Free Uncle Bulgaria" has been debated 30 days ago
    And a petition "Ban Badger Baiting" has been debated 12 days ago
    And I am on the home page
    Then I should see "Ban Badger Baiting" in the debate threshold section
    And I should not see "Free the wombles" in the debate threshold section
