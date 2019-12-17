# feature/home page. feature
Feature: Home page
  As a creator of team
   want to create a project
   want to edit, archive project
   want to add user, comment to a project

Background:
Given the following users is registered:
 | name                 | email              | password  | team                 | role   |
 | Karli Novak (creator)| nonadmin@myorg.com | asdf1243  | BioSistemika Process | admin  |
 | Marija Novak         | marija@myorg.com   | asdf1243  | BioSistemika Process |  admin |
 And "nonadmin@myorg.com" is signed in with "asdf1243"

 Scenario: Successful create new project
   Given I am on the home page of Biosistemika Process team
   And I click on "New Project" button
   And I fill in "Mangart" in New Project input field 
   And I click on "All team members" button 
   And I click on "Create" class button
   Then I should see "Project Mangart successfully created." flash message
   Then I should see "Mangart" project card in BioSistemika Process team page

 Scenario: Unsuccessful create new project1
   Given I am on the home page of Biosistemika Process team
   And I click on "New Project" button
   And I click on "Create" class button
   Then I should see "is too short (minimum is 2 characters)" message of "Create new project" modal window
   And I click on "Cancel" button

 Scenario: Unsuccessful create new project2
   Given I am on the home page of Biosistemika Process team
   And I click on "New Project" button
   And I fill in "Mangart" in New Project input field 
   And I click on "Create" class button
   And I click on "New Project" button
   And I fill in "Mangart" in New Project input field 
   And I click on "Create" class button
   And I make screenshot
   Then I should see "This project name has to be unique inside a team (this includes the archive)" message of "Create new project" modal window

 Scenario: Successful edit project
   Given I'm on the home page of "Biosistemika Process" team
   And I click to down arrow of a "Mangart" project card
   And I click to "Edit" of a Options modal window
   Then I change "Mangart" Project name with "Golica" Project name of "Edit project Mangart" modal window
   And I click on "Project members only" button
   And I click on "Save" button
   Then I should see "Golica" project card in "BioSistemika Process" team page

 Scenario: Successful add user to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on users avatar of a "Golica" project card
   And I click on "Manage users" on "Golica" project card
   And I click on "Marija Novak" in users dropdown menu of a "Manage users for Golica" modal window
   And I click on "User" in Select Role dropdown menu of a "Manage users for Golica" modal window
   And I click on "Add" button of a "Manage users for Golica" modal window
   And I click on "Close" button
   Then I should see "Marija Novak" in Users list of "Golica" project card

  Scenario: Successful change user role to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on users avatar of a "Golica" project card
   And I click on "Manage users" on "Golica" project card
   And I click on "Owner" in Change Role dropdown menu of a "Manage users for Golica" modal window
   And I click on "Close" button
   Then I should see "Owner" under Marija Novak in Users list of "Golica" project card

  Scenario: Successful add new SciNote user to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on users avatar of a "Golica" project card
   And I click on "Manage users" on "Golica" project card
   And I click on "Invite users" of a "Manage users for Golica" modal window
   Then I should see team BioSistemika Process settings page of a Karli Novak user

 Scenario: Unsuccessful adding user to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on users avatar of a "Golica" project card
   And I click on "Manage users" on "Golica" project card
   And I click on "Marija Novak" in users dropdown menu of a "Manage users for Golica" modal window
   And I click on "Add" button of a "Manage users for Golica" modal window
   Then I should see Text "Plese select a user role."
   And I click on "Close" button

 Scenario: Removing user from a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on users avatar of a "Golica" project card
   And I click on "Manage users" on "Golica" project card
   And I click on "X" sign at "Marija Novak" user in dropdown menu of a "Manage users for Golica" modal window
   Then "Marija Novak" user is removed from a list in dropdown menu of a "Manage users for Golica" modal window
   And I click on "Close" button

 Scenario: Successful add comment to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And I add "I was on Triglav one summer." in comment field
   And I click on "paper plane" sign
   Then I should see "I was on Triglav one summer." in Comments list of "Golica" project card

 Scenario: Unsuccessful add comment to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And I click on "paper plane" sign
   Then I should see "Message can't be blank" error message 

 Scenario: Successful edit comment to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And I click on field of a "I was on Triglav one summer." comment
   And I change "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more."
   And I click on "Save" sign
   Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of "Golica" project card

 Scenario: Unsuccessful edit comment to a project
  Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And I click on field of a "I was on Triglav one summer." comment
   And I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click on "X" sign
   Then I should see "I was on Triglav one summer." in Comments list of "Golica" project card

 Scenario: Unsuccessful delete comment to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And place mouse on "I was on Triglav one summer."
   And I click on "trashcan" 
   And I click to Cancel on confirm dialog
   Then I should see "I was on Triglav one summer." in Comments list of "Golica" project card

 Scenario: Successful delete comment to a project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And place mouse on "I was on Triglav one summer."
   And I click on "trashcan"
   And I click to OK on confirm dialog
   Then "I was on Triglav one summer." comment is removed from Comments list of "Golica"

 Scenario: Unsuccessful archived project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on down arrow of a "Golica" project card
   And I click on "Archive" of a Options modal window
   And I click to Cancel on confirm dialog
   Then I should see "Golica" project card in "BioSistemika Process" team page

 Scenario: Successful archived project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on down arrow of a "Golica" project card
   And I click on "Archive" of a Options modal window
   And I click to OK on confirm dialog
   Then I should see "Project Golica successfully archived." flash message

 Scenario: Restore archived project
   Given I'm on the home page of "Biosistemika Process" team
   And I click on "Archived" button
   And I should see "Golica"
   And I click to down arrow of a "Golica" project card
   And I click to "Restore" of a Options modal window
   Then I should see "Project Golica successfully restored." flash message
