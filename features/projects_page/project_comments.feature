Feature: Project page/Project comments
  As a creator of team
  I want to add/edit/delete comments on project

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
Scenario: Successful add comment to a project
  And I click "comment" icon on "Mangart" project card
  Then I add "I was on Triglav one summer." in comment field on "Mangart" project card
  And I click to send comment button on "Mangart" project card
  Then I should see "I was on Triglav one summer." in Comments list of "Mangart" project card

@javascript
Scenario: Can't add empty comment to a project
  And I click "comment" icon on "Mangart" project card
  And I don't have send comment button on "Mangart" project card

@javascript
Scenario: Successful edit comment to a project
  And user "Karli Novak" has comment "I was on Triglav one summer." on project "Mangart"
  And I click "comment" icon on "Mangart" project card
  And I click on "I was on Triglav one summer." comment to edit it on "Mangart" project card
  Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment on "Mangart" project card
  And I click "save" icon on "Mangart" project card
  Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of "Mangart" project card

@javascript
Scenario: Unsuccessful edit comment to a project
  And user "Karli Novak" has comment "I was on Triglav one summer." on project "Mangart"
  And I click "comment" icon on "Mangart" project card
  And I click on "I was on Triglav one summer." comment to edit it on "Mangart" project card
  Then I change "I was on Triglav one summer." comment with "" comment on "Mangart" project card
  And I click "save" icon on "Mangart" project card
  Then I should see "Message can't be blank" error message

@javascript
Scenario: Unsuccessful delete comment to a project
  And user "Karli Novak" has comment "I was on Triglav one summer." on project "Mangart"
  And I click "comment" icon on "Mangart" project card
  And I hover "I was on Triglav one summer." comment on "Mangart" project card
  And I click "trash" icon on "Mangart" project card
  And I click to Cancel on confirm dialog
  Then I should see "I was on Triglav one summer." in Comments list of "Mangart" project card

@javascript @wip
Scenario: Successful delete comment to a project
  And user "Karli Novak" has comment "I was on Triglav one summer." on project "Mangart"
  And I click "comment" icon on "Mangart" project card
  And I hover "I was on Triglav one summer." comment on "Mangart" project card
  And I click "trash" icon on "Mangart" project card
  And I click to OK on confirm dialog
  Then I shouldn't see "I was on Triglav one summer." in Comments list of "Mangart" project card
