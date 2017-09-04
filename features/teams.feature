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

 Scenario: Add team description
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to "i" blue button
   Then I fill in "I was on Triglav one summer." to Description field of "Edit team description" modal window
   And I click on "Update" button
   Then I should see "I was on Triglav one summer." in team description field

 Scenario: Change team name
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to "BioSistemika Process Company" team name link
   Then I change "BioSistemika Process Company" description with "BioSistemika Process" description to Name field of "Edit team name" modal window
   And I click on "Update" button
   Then I should see "BioSistemika Process" in team name field

 Scenario: Change team description
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to "i" blue button
   Then I change "I was on Triglav one summer." description with "I want to go to Nanos." description to Description field of "Edit team description" modal window
   And I click on "Update" button
   Then I should see "I want to go to Nanos." in team description field

 Scenario: Change user role
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to Action button of a Marija Novak user in Team members table
   Then I click to "Guest" in User role modal window
   Then I should see "Guest" in Role column of a Marija Novak user in Team members table

 Scenario: Change user role
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to Action button of a Suazana Novak user in Team members table
   Then I click to "Normal user" in User role modal window
   Then I should see "Normal user" in Role column of a Suazana Novak user in Team members table

 Scenario: Change user role
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to Action button of a Marija Novak user in Team members table
   Then I click to "Administrator" in User role modal window
   Then I should see "Administrator" in Role column of a Marija Novak user in Team members table

 Scenario: Change user role
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to Action button of a Suazana Novak user in Team members table
   Then I click to "Administrator" in User role modal window
   Then I should see "Administratorr" in Role column of a Suazana Novak user in Team members table

 Scenario: Change user role
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to Action button of a Suazana Novak user in Team members table
   Then I click to "Normal user" in User role modal window
   Then I should see "Normal user" in Role column of a Suazana Novak user in Team members table

 Scenario: User is removed
   Given team BioSistemika Process settings page of a Karli Novak user
   And I click to Action button of a Suazana Novak user in Team members table
   Then I click to "Remove" in User role modal window
   Then I should not see Suazana Novak user in Team members table

Scenario: User left a team
   Given team BioSistemika Process settings page of a Marija Novak user
   And I click to Leave team button of BioSistemika Process team in Team table
   Then I click to Leave button of "Leave team BioSistemika Process" modal window
   Then I should see "Successfuly left team BioSistemika Process."
