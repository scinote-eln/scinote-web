# feature/home page. feature
Feature: Home page
  As a creator of team
  I want to create a project
  I want to edit, archive project
  I want to add user, comment to a project

Background:
  Given default screen size
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name         | email              | password       | password_confirmation |
     | Karli Novak  | nonadmin@myorg.com | mypassword1234 | mypassword1234        |
     | Marija Novak | marija@myorg.com   | mypassword5555 | mypassword5555        |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  And "marija@myorg.com" is in "BioSistemika Process" team as a "normal_user"
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

 @javascript
 Scenario: Successful create new project
   Given I'm on the home page of "BioSistemika Process" team
   And I click "New Project" Scinote button
   Then I fill in "Mangart" to "Project name" field of "Create new project" modal window
   And I click "All team members" Scinote button
   And I click "Create" button
   Then I should see "Project Mangart successfully created." flash message
   Then I should see "Mangart" public project card in "BioSistemika Process" team page

 @javascript
 Scenario: Unsuccessful create new project
   Given I had project "Mangart" for team "BioSistemika Process"
   Given I'm on the home page of "BioSistemika Process" team
   And I click "New Project" Scinote button
   And I click "Create" button
   Then I should see "is too short (minimum is 2 characters)" error message of "Create new project" modal window
   Then I fill in "Mangart" to "Project name" field of "Create new project" modal window
   And I click "Create" button
   Then I should see "This project name has to be unique inside a team (this includes the archive)" error message of "Create new project" modal window
   And I click "Cancel" Scinote button

 @javascript
 Scenario: Successful edit project
   Given I had project "Mangart" for team "BioSistemika Process"
   And user "Karli Novak" owner of project "Mangart"
   Given I'm on the home page of "BioSistemika Process" team
   And I click to down arrow of a "Mangart" project card
   And I click to "Edit" of a Options modal window
   Then I change "Mangart" with "Golica" of field "Project name" of "Edit project Mangart" modal window
   And I click "Project members only" Scinote button
   And I click "Save" button
   Then I should see "Golica" private project card in "BioSistemika Process" team page

 @javascript
 Scenario: Successful add user to a project
   Given I had project "Mangart" for team "BioSistemika Process"
   And user "Karli Novak" owner of project "Mangart"
   And I'm on the home page of "BioSistemika Process" team
   And I click "users" icon on "Mangart" project card
   And I click "Manage users" link
   And I select user "Marija Novak" in user dropdown of user manage modal for project "Mangart"
   And I select role "User" in role dropdown of user manage modal for project "Mangart"
   And I click "Add" Scinote button
   And I click "Close" Scinote button
   Then I should see "Marija Novak" with role "User" in Users list of "Mangart" project card

  @javascript
  Scenario: Successful change user role to a project
   Given I had project "Mangart" for team "BioSistemika Process"
   And user "Karli Novak" owner of project "Mangart"
   And user "Marija Novak" normal user of project "Mangart"
   And I'm on the home page of "BioSistemika Process" team
   And I click "users" icon on "Mangart" project card
   And I click "Manage users" link
   And I change role "Owner" in role dropdown for user "Marija Nova" of user manage modal for project "Mangart"
   And I click "Close" Scinote button
   Then I should see "Marija Novak" with role "Owner" in Users list of "Mangart" project card

  @javascript
  Scenario: Successful add new SciNote user to a project
   Given I had project "Mangart" for team "BioSistemika Process"
   And user "Karli Novak" owner of project "Mangart"
   And I'm on the home page of "BioSistemika Process" team
   
   And I click "users" icon on "Mangart" project card
   And I click "Manage users" link
   And I click "Invite users" link
   Then I should see team "BioSistemika Process" settings page of a current user

 @javascript
 Scenario: Unsuccessful adding user to a project
   Given I had project "Mangart" for team "BioSistemika Process"
   And user "Karli Novak" owner of project "Mangart"
   And I'm on the home page of "BioSistemika Process" team

   And I click "users" icon on "Mangart" project card
   And I click "Manage users" link
   And I select user "Marija Novak" in user dropdown of user manage modal for project "Mangart"
   And I click "Add" Scinote button
   Then I should see "Please select a user role." error message
   And I click "Close" Scinote button

 @javascript
 Scenario: Removing user from a project
   Given I had project "Mangart" for team "BioSistemika Process"
   And user "Karli Novak" owner of project "Mangart"
   And I'm on the home page of "BioSistemika Process" team

   And I click to avatar of a "Golica" project card
   Then I click to "Manage users" on "Golica" project card
   And I click to "X" sign at "Marija Novak" user in dropdown menu of a "Manage users for Golica" modal window
   Then "Marija Novak" user is removed from a list in dropdown menu of a "Manage users for Golica" modal window
   And I click to "Close" button

 Scenario: Successful add comment to a project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to Comments of a "Golica" project card
   Then I add "I was on Triglav one summer." in comment field
   And I click to "+" sign
   Then I should see "I was on Triglav one summer." in Comments list of "Golica" project card

 Scenario: Unsuccessful add comment to a project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to Comments of a "Golica" project card
   And I click to "+" sign
   Then I should see "Message can't be blank" red error message under comment field in Comments list of "Golica" project card

 Scenario: Successful edit comment to a project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to Comments of a "Golica" project card
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "OK" sign
   Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of "Golica" project card

 Scenario: Unsuccessful edit comment to a project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to Comments of a "Golica" project card
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "Cancel" sign
   Then I should see "I was on Triglav one summer." in Comments list of "Golica" project card

 Scenario: Unsuccessful delete comment to a project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to Comments of a "Golica" project card
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
   Then I should see "I was on Triglav one summer." in Comments list of "Golica" project card

 Scenario: Successful delete comment to a project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to Comments of a "Golica" project card
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
   Then "I was on Triglav one summer." comment is removed from Comments list of "Golica" project card

 Scenario: Unsuccessful archived project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to down arrow of a "Mangart" project card
   And I click to "Archive" of a Options modal window
   And I click to "Cancel" button in "Are you sure to archive project?" modal window
   Then I should see "Golica" privat project card in "BioSistemika Process" team page

 Scenario: Successful archived project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to down arrow of a "Mangart" project card
   And I click to "Archive" of a Options modal window
   And I click to "OK" button in "Are you sure to archive project?" modal window
   Then I should see "Project Golica successfully archived." flash message

 Scenario: Restore archived project
   Given home page of BioSistemika Process team of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "Golica" project
   And I click to down arrow of a "Golica" project card
   And I click to "Restore" of a Options modal window
   Then I should see "Project Golica successfully restored." flash message
