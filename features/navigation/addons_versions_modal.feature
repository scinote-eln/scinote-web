Feature: Addon versions
  As a sciNote User
  I want know what addon are activated
  So that I know what features are enabled

  Background:
    Given the "BioSistemika Process" team exists
    Given the following users are registered
     | email                   | password           | password_confirmation | full_name   | initials  |
     | admin@myorg.com         | mypassword1234     | mypassword1234        | Karli Novak | KN        |
    And "admin@myorg.com" is in "BioSistemika Process" team as a "admin"
    And "admin@myorg.com" is signed in with "mypassword1234"

  @javascript
  Scenario: Open the sciNote addons modal
    Given I'm on the profile page
    And I click "#nav-info-dropdown" icon
    And I click "About sciNote" link within ".dropdown.open"
    Then I should see "About sciNote"
    And I should see "sciNote core version"
