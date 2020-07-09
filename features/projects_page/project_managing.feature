Feature: Project page/Project managing
  As a creator of team
  I want to create/edit a project

Background:
  Given default screen size
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name         | email              | password       | password_confirmation |
     | Karli Novak  | nonadmin@myorg.com | mypassword1234 | mypassword1234        |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

@javascript
Scenario: Successful create new project
  Given I'm on the projects page of "BioSistemika Process" team
  And I click "New Project" button
  Then I fill in "Mangart" to "Project name" field of "Create new project" modal window
  And I click "All team members" button
  And I click "Create" button
  Then I should see "Project Mangart successfully created." flash message
  Then I should see "Mangart" public project card in "BioSistemika Process" team page

@javascript
Scenario: Unsuccessful create new project
  Given I had project "Mangart" for team "BioSistemika Process"
  Given I'm on the projects page of "BioSistemika Process" team
  And I click "New Project" button
  And I click "Create" button
  Then I should see "is too short (minimum is 2 characters)" error message of "Create new project" modal window
  Then I fill in "Mangart" to "Project name" field of "Create new project" modal window
  And I click "Create" button
  Then I should see "This project name has to be unique inside a team (this includes the archive)" error message of "Create new project" modal window
  And I click "Cancel" button

@javascript
Scenario: Successful edit project
  Given I had project "Mangart" for team "BioSistemika Process"
  And user "Karli Novak" owner of project "Mangart"
  Given I'm on the projects page of "BioSistemika Process" team
  And I click to down arrow of a "Mangart" project card
  And I click to "Edit" of a Options modal window
  Then I fill in "Golica" in "#project_name" field
  And I click "Project members only" button
  And I click "Save" button
  Then I should see "Golica" private project card in "BioSistemika Process" team page
