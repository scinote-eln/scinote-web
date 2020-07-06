Feature: Project page/Project users
  As a creator of team
  I want to add/edit/delete users on project

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
  And I had project "Mangart" for team "BioSistemika Process"
  And user "Karli Novak" owner of project "Mangart"
  And I'm on the projects page of "BioSistemika Process" team


@javascript
Scenario: Successful add user to a project
  And I click "users" icon on "Mangart" project card
  And I click "Manage users" link
  And I select user "Marija Novak" in user dropdown of user manage modal for project "Mangart"
  And I select role "User" in role dropdown of user manage modal for project "Mangart"
  And I click "Add" button
  And WAIT
  And I click "Close" button
  Then I should see "Marija Novak" with role "User" in Users list of "Mangart" project card

@javascript
Scenario: Successful change user role to a project
  And user "Marija Novak" normal user of project "Mangart"
  And I click "users" icon on "Mangart" project card
  And I click "Manage users" link
  And I change role "Owner" in role dropdown for user "Marija Nova" of user manage modal for project "Mangart"
  And WAIT
  And I click "Close" button
  Then I should see "Marija Novak" with role "Owner" in Users list of "Mangart" project card

@javascript
Scenario: Successful add new SciNote user to a project
  And I click "users" icon on "Mangart" project card
  And I click "Manage users" link
  And I click "Invite users" link
  Then I should see team "BioSistemika Process" settings page of a current user

@javascript
Scenario: Unsuccessful adding user to a project
  And I click "users" icon on "Mangart" project card
  And I click "Manage users" link
  And I select user "Marija Novak" in user dropdown of user manage modal for project "Mangart"
  And I click "Add" button
  Then I should see "Please select a user role." error message
  And I click "Close" button

@javascript
Scenario: Removing user from a project
  And user "Marija Novak" normal user of project "Mangart"
  And I click "users" icon on "Mangart" project card
  And I click "Manage users" link
  And I click to cross icon at "Marija Novak" user in user manage modal for project "Mangart"
  Then "Marija Novak" user is removed from a list in user manage modal for project "Mangart"
  And I click "Close" button
