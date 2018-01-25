# feature/teams.feature
Feature: Teams settings
  As a creator of team
  I want to change a user role
  I want to add and change team description
  I want to edit team name

Background:
Given the following users is registered:
 | name                 | email              | password        | team                 | role        |
 |Karli Novak (creator)| nonadmin@myorg.com | mypassword1234  | BioSistemika Process Company | Administrator|
 |Marija Novak         | marija@myorg.com   | mypassword5555  | BioSistemika Process |  Normal user |
 |Suazana Novak        | suazana@myorg.com  | mypassword6666  | BioSistemika Process |  Guest user |

Scenario: User left a team
   Given team BioSistemika Process settings page of a Marija Novak user
   And I click to Leave team button of BioSistemika Process team in Team table
   Then I click to Leave button of "Leave team BioSistemika Process" modal window
   Then I should see "Successfuly left team BioSistemika Process."
