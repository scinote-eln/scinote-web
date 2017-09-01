# feature/gamification. feature
Feature: Completing gamification
  As a creator of team
  I want to finish gamification and earn 1 GB team space
  I want to earn up to 10 GB team space

Background:
Given the following users is registered:
 | name                 | email              | password        | team                 | role        |
 |Karli Novak (creator)| nonadmin@myorg.com | mypassword1234  | BioSistemika Process | Administrator|

 Scenario: Successful first login to sciNote
   Given sign up to sciNote BioSistemika Process team of a Karli Novak user
   And I click to "I am ready to start" button of a "Welcome to sciNote" modal window
   Then I should see start of tutorial
   And I click to "SKIP TUTORIAL" button
   Then I should see "1/4" completed basic steps of 4 basic steps

 Scenario: Successful create new project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to "New project" button
   Then I fill in "Golica" to Project name field of "Create new project" modal window
   And I click on "Create project" button
   Then I should see "Project Golica successfully created." flash message
   Then I should see "2/4" completed basic steps of 4 basic steps

 Scenario: Successful create new experiment
   Given Golica project page of a Karli Novak user
   And I click to "Create new experiment" card
   Then I fill in "Narcisa" to Experiment name field of "Create new experiment" modal window
   Then I fill in "Pozno spomladi cvetijo narcise." to Description field of "Create new experiment" modal window
   And I click on "Create experiment" button
   Then I should see "Project successfully updated." flash message
   Then I should see 2 GB of a team space
   Then I should see 13 leaves

 Scenario: Successful earn 8 GB invating users to sciNote
   Given Profile page of a Karli Novak user
   Then I should see 13 leaves
   Then I should see 2 GB of a team space
   And I click on avatar
   And I click to "Invite people to sciNote"
   Then I fill in "nikola@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "marija@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "luka@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "matej@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "mojca@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "nika@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "lana@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   Then I fill in "petra@myorg.com" to Invite people to sciNote input field
   And confirm with ENTER key
   And I click on checkbox "Invite user to my team"
   And I click on "Invite user/s" button
   And I click on "as Normal user/s" modal window
   Then I should see "nikola@myorg.com - User successfully invited to sciNote and team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "marija@myorg.com - User is already a member of sciNote - successfully invited to team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "luka@myorg.com - User successfully invited to sciNote and team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "matej@myorg.com - User is already a member of sciNote - successfully invited to team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "mojca@myorg.com - User successfully invited to sciNote and team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "nika@myorg.com - User is already a member of sciNote - successfully invited to team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "lana@myorg.com - User successfully invited to sciNote and team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   Then I should see "petra@myorg.com - User is already a member of sciNote - successfully invited to team BioSistemika Process as Normal user." Invitation results in Invite people to sciNote modal window
   And I click on "Close" button
   Then I should see 10 GB of a team space
   Then I should see earned 93 leaves
