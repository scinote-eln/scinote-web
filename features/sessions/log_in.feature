Feature: Log in
  As an existing User
  I want to Log in with my account
  So that I can use SciNote

Background:
  Given default screen size
  Given the "BioSistemika Process" team exists
  Given the following users are registered
    | email                     | password          | password_confirmation |
    | night.slarker@gmail.com   | mypassword1234    | mypassword1234        |
  And "night.slarker@gmail.com" is in "BioSistemika Process" team as a "admin"

@javascript
Scenario: Successful Log in
  Given I am on Log in page
  Then I fill in Email "night.slarker@gmail.com" and Password "mypassword1234"
  And I click "Log in" button
  Then I should be on homepage

@javascript
Scenario: Unsuccessful Log in
  Given I am on Log in page
  And I click "Log in" button
  Then I should see "Invalid Email or password." flash message

@javascript
Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I fill in Email "monday@myorg.com" and Password "monday1234"
  And I click "Log in" button
  Then I should see "Invalid Email or password." flash message

@javascript
Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I fill in Email "night.slarker@gmail.com" and Password "mypassword123455"
  And I click "Log in" button
  Then I should see "Invalid Email or password." flash message

@javascript
Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I fill in Email "monday@myorg.com" and Password "mypassword1234"
  And I click "Log in" button
  Then I should see "Invalid Email or password." flash message

@javascript
Scenario: Successful Log out
  Given "night.slarker@gmail.com" is signed in with "mypassword1234"
  And I'm on the projects page of "BioSistemika Process" team
  And I click element with css "#user-account-dropdown"
  And I click "Log out" link
  Then I should see "Logged out successfully." flash message
