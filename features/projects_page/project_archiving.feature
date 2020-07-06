Feature: Project page/Project archiving
  As a creator of team
  I want to archive/restore project

Background:
  Given default screen size
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name         | email              | password       | password_confirmation |
     | Karli Novak  | nonadmin@myorg.com | mypassword1234 | mypassword1234        |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  And "nonadmin@myorg.com" is signed in with "mypassword1234"
  Given I had project "Mangart" for team "BioSistemika Process"
  And user "Karli Novak" owner of project "Mangart"
  And I'm on the projects page of "BioSistemika Process" team

@javascript
Scenario: Unsuccessful archived project
  And I click to down arrow of a "Mangart" project card
  And I click to "Archive" of a Options modal window
  And I click to Cancel on confirm dialog
  Then I should see "Mangart" private project card in "BioSistemika Process" team page

@javascript
Scenario: Successful archived project
  And I click to down arrow of a "Mangart" project card
  And I click to "Archive" of a Options modal window
  And I click to OK on confirm dialog
  Then I should see "Project Mangart successfully archived." flash message

@javascript
Scenario: Restore archived project
  And project "Mangart" archived
  And I click to "ARCHIVED" tab
  Then I should see "Mangart" archived project card in "BioSistemika Process" team page
  And I click to down arrow of a "Mangart" project card
  And I click to "Restore" of a Options modal window
  Then I should see "Project Mangart successfully restored." flash message
