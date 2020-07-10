Feature: Invite people to SciNote
  As an owner of a team
  Want to add new User to my team throughout the SciNote

  Background:
    Given default screen size
    Given the following users are registered:
      | name         | email              | password | team                 | role  |
      | Karli Novak  | nonadmin@myorg.com | asdf1243 | BioSistemika Process | admin |
      | Marija Novak | marija@myorg.com   | asdf1243 | Cell                 | admin |
 #And "nonadmin@myorg.com" is signed in with "asdf1243" - Cannot be used here if you want to access "Sign up" page

  @javascript
  Scenario: Successful Add team member1
    Given "nonadmin@myorg.com" is signed in with "asdf1243"
    And Settings page of BioSistemika Process team of a Karli Novak user
    And I click "Add team members" button
    And I fill bootsrap tags input with "lojze@myorg.com"
    And confirm with ENTER key to ".bootstrap-tagsinput>input"
    And I click "Invite Users" button
    And I click "As Normal Users" link
    Then I should see "lojze@myorg.com  -  User successfully invited to SciNote and team BioSistemika Process as Normal user." massage of "Invitation results:" modal window
    And I click "Close" button
    And I should see "pending"
    And I should see "lojze@myorg.com"

  @javascript
  Scenario: Successful Add team member2
    Given "nonadmin@myorg.com" is signed in with "asdf1243"
    And Settings page of BioSistemika Process team of a Karli Novak user
    And I click "Add team members" button
    And I fill bootsrap tags input with "marija@myorg.com"
    And confirm with ENTER key to ".bootstrap-tagsinput>input"
    And I click "Invite Users" button
    And I click "As Normal Users" link
    Then I should see "marija@myorg.com  -  User was already a member of SciNote - successfully invited to team BioSistemika Process as Normal user." massage of "Invitation results:" modal window
    And I click "Close" button
    And I should see "active"
    And I should see "marija@myorg.com"

  @javascript
  Scenario: Checking Add team members
    Given "nonadmin@myorg.com" is signed in with "asdf1243"
    And Settings page of BioSistemika Process team of a Karli Novak user
    And I click "Add team members" button
    And I fill bootsrap tags input with "marija@myorg.com"
    And confirm with ENTER key to ".bootstrap-tagsinput>input"
    And I fill bootsrap tags input with "lojze@myorg.com"
    And confirm with ENTER key to ".bootstrap-tagsinput>input"
    And I click "Invite Users" button
    And I click "As Normal Users" link
    And I click "Close" button
    Then I should see "active"
    Then I should see "pending"
    Then I should see "marija@myorg.com"
    Then I should see "lojze@myorg.com"

  @javascript
  Scenario: Unsuccessful Add team member
    Given "nonadmin@myorg.com" is signed in with "asdf1243"
    And Settings page of BioSistemika Process team of a Karli Novak user
    And I click "Add team members" button
    And I fill bootsrap tags input with "anicamyorg.com"
    And confirm with ENTER key to ".bootstrap-tagsinput>input"
    And I click "Invite Users" button
    And I click "As Normal Users" link
    Then I should see "anicamyorg.com  -  Invalid email." massage of "Invitation results:" modal window
    And I click "Close" button

  @javascript
  Scenario: Successful Sign up
    Given I visit the sign up page
    And I fill in "Karolina" in "#user_full_name" field
    And I fill in "mypassword3333" in "#user_password" field
    And I fill in "karolina@myorg.com" in "#user_email" field
    And I fill in "mypassword3333" in "#user_password_confirmation" field
    And I fill in "Circle" in "#team_name" field
    And I click "Sign up" button
    And I should see "Circle"
    Then I should see "Hi, Karolina"

  @javascript
  Scenario: Unsuccessful Sign up, Password confirmation does not match
    Given I visit the sign up page
    And I fill in "Agata Novakovic" in "#user_full_name" field
    And I fill in "mypassword6666" in "#user_password" field
    And I fill in "agata@myorg.com" in "#user_email" field
    And I fill in "mypassword6665 " in "#user_password_confirmation" field
    And I fill in "Flop" in "#team_name" field
    And I click "Sign up" button
    Then I should see "doesn't match Password" error message

  @javascript
  Scenario: Unsuccessful Sign up, Team name is missing
    Given I visit the sign up page
    And I fill in "Agata Novakovic" in "#user_full_name" field
    And I fill in "mypassword6666" in "#user_password" field
    And I fill in "agata@myorg.com" in "#user_email" field
    And I fill in "mypassword6666" in "#user_password_confirmation" field
    And I click "Sign up" button
    Then I should see "is too short (minimum is 2 characters)" error message

