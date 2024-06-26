Feature: Suzie signs a petition
  In order to have my say
  As Suzie
  I want to sign an existing petition

  Background:
    Given a petition "Do something!"

  Scenario: Suzie signs a petition after validating her email
    When I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should have signed the petition

  Scenario: Suzie signs a petition after validating her email
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
    And I fill in my details with email "womboid@wimbledon.com"
    And I fill in my postcode with "JE1 1AA"
    And I try to sign
    Then I am asked to review my email address
    When I change my email address to "womboidian@wimbledon.com"
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive no email
    And "womboidian@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should see "2 signatures"
    And I should see my parish "St. Saviour"
    And I can click on a link to return to the petition
    And I should see "2 signatures"

  Scenario: Suzie signs a petition after validating her email when local petitions are disabled
    Given the site has disabled local petitions
    When I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should have signed the petition
    And I should not see my parish "St. Saviour"

  Scenario: Suzie signs a petition with invalid postcode JE1 9ZZ
    When I go to the new signature page for "Do something!"
    And I fill in my details with email "womboid@wimbledon.com"
    And I fill in my postcode with "JE1 9ZZ"
    And I try to sign
    Then I am asked to review my email address
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
    Then I should see "2 signatures"
    And I should not see the text "Your parish is"

  Scenario: Suzie cannot sign if she is not a Jersey resident
    When I decide to sign the petition
    And I fill in my non-Jersey details
    And I try to sign
    Then I should see an error

  Scenario: Suzie cannot sign if her IP is blocked
    Given my IP address is blocked
    When I decide to sign the petition
    Then I should see "We've detected that your IP address is from outside Jersey"

  Scenario: Suzie receives a duplicate signature email if she tries to sign but she has already signed and validated
    When I have already signed the petition with an uppercase email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then "womboid@wimbledon.com" should receive 1 email with subject "Duplicate signature of petition"

  Scenario: Suzie receives a duplicate signature email if she changes to her original email but she has already signed and validated
    When I have already signed the petition with an uppercase email
    And I decide to sign the petition
    And I fill in my details
    And I fill in my details with email "womboidian@wimbledon.com"
    And I try to sign
    When I change my email address to "womboid@wimbledon.com"
    And I say I am happy with my email address
    Then "womboid@wimbledon.com" should receive 1 email with subject "Duplicate signature of petition"

  Scenario: Suzie receives another email if she has already signed but not validated
    When I have already signed the petition but not validated my email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then the signature count stays at 2
    And I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie receives an email if her email has been used to sign the petition already
    When Eric has already signed the petition with Suzies email
    And I decide to sign the petition
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then the signature count goes up to 3
    And I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email

  Scenario: Suzie cannot sign if she does not provide her details
    When I decide to sign the petition
    And I try to sign
    Then I should see an error

  Scenario: Suzie sees notice that she has already signed when she validates more than once
    When I fill in my details and sign a petition
    And I confirm my email address
    And I should see "2 signatures"
    And I should see "We've added your signature to the petition"
    And I can click on a link to return to the petition
    And I should have signed the petition
    When I confirm my email address again
    And I should see "2 signatures"
    And I should see "We've added your signature to the petition"
    And I can click on a link to return to the petition

  Scenario: Eric clicks the link shared to him by Suzie
    When Suzie has already signed the petition and validated her email
    And Suzie shares the signatory confirmation link with Eric
    And I click the shared link
    Then I should see "Sign this petition"

  Scenario: Suzie cannot start a new signature when the petition has closed
    Given the petition has closed
    When I go to the new signature page
    Then I should be on the petition page
    And I should see "This petition is closed"

  Scenario: Suzie cannot create a new signature when the petition has closed
    Given I am on the new signature page
    And the petition has closed
    When I fill in my details
    And I try to sign
    Then I should be on the petition page
    And I should see "This petition is closed"

  Scenario: Suzie cannot confirm her email when the petition has closed
    Given I am on the new signature page
    When I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When the petition has closed
    And I say I am happy with my email address
    Then I should be on the petition page
    And I should see "This petition is closed"

  Scenario: Suzie cannot validate her signature when the petition has closed
    Given I am on the new signature page
    When I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When the petition has closed some time ago
    And I confirm my email address
    Then I should be on the petition page
    And I should see "This petition is closed"
    And I should see "1 signature"

  Scenario: Suzie can validate her signature when the petition has closed recently
    Given I am on the new signature page
    When I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
    When the petition has closed
    And I confirm my email address
    Then I should see "We've added your signature to the petition"
    And I should see "2 signatures"
    When I follow "Do something!"
    Then I should be on the petition page
    And I should see "This petition is closed"
    And I should see "2 signatures"

  Scenario: Suzie cannot validate her signature when IP address is rate limited
    Given the burst rate limit is 1 per minute
    And there are no allowed IPs
    And there is a signature already from this IP address
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should have no emails

  Scenario: Suzie can validate her signature when IP address is rate limited but the domain is allowed
    Given the burst rate limit is 1 per minute
    And there are no allowed IPs
    And the domain "wimbledon.com" is allowed
    And there is a signature already from this IP address
    When I am on the new signature page
    And I fill in my details
    And I try to sign
    Then I should be on the new signature page
    When I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
