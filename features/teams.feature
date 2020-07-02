# feature/teams.feature
Feature: Teams settings
  As a normal user
  I want to left a team

Background:
Given the "BioSistemika Process" team exists
And the following users are registered
  | name                 | email              | password        | password_confirmation |
  |Karli Novak (creator) |nonadmin@myorg.com  |mypassword1234   |mypassword1234        |
  |Marija Novak          |marija@myorg.com    |mypassword1234   |mypassword1234        |
And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
And "marija@myorg.com" is in "BioSistemika Process" team as a "normal_user"
And "marija@myorg.com" is signed in with "mypassword1234"

  @javascript
  Scenario: User left a team
   Given team settings page
   And I click "Leave team" button
   And I click element with css ".btn-danger"
   Then I should see "Successfuly left team BioSistemika Process."
