# feature/project. feature
Feature: Project
  As a creator of team
  I want to navigate to other my team
  I want to navigate through a SciNote

Background:
Given default screen size
Given the "BioSistemika Process" team exists
Given the "BioSistemika Path" team exists
Given the following users are registered
  | name         | email              | password        | password_confirmation |
  |Karli Novak   | nonadmin@myorg.com | mypassword1234  | mypassword1234        |
And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
And "nonadmin@myorg.com" is in "BioSistemika Path" team as a "normal_user"
And "nonadmin@myorg.com" is signed in with "mypassword1234"

  @javascript
  Scenario: Successful change a team view
    Given I'm on the projects page of "BioSistemika Path" team
    And I click on team switcher
    And I click to "BioSistemika Process" in team dropdown menu
    Then I should see "You are working on BioSistemika Process now!" flash message

  Scenario: Successful return to Projects page
    Given My profile page of current user
    And I click first "Projects" link
    Then I am on Projects page of "BioSistemika Process" team of current user

  Scenario: Successful navigate to Protocols page
    Given My profile page of current user
    And I click first "Protocols" link
    Then I am on Protocols page of "BioSistemika Process" team of current user

  Scenario: Successful navigate to Inventories page
    Given My profile page of current user
    And I click first "Inventories" link
    Then I am on Inventories page of "BioSistemika Process" team of current user

  Scenario: Successful navigate to Reports page
    Given My profile page of current user
    And I click first "Reports" link
    Then I am on Reports page of "BioSistemika Process" team of current user

  Scenario: Successful navigate to Activities page
    Given My profile page of current user
    And I click first "Activities" link
    Then I am on Activities page of "BioSistemika Process" team of current user
