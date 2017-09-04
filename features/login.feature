# feature/login.feature
Feature: Log in / Log out
  As a user with account
  I want to Log in with my account
  So that I can use sciNote
  I want to Log out

Background:
  Given the following users is registered:
    | email                   | password           | team
    | nonadmin@myorg.com      | mypassword1234     | BioSistemika Process

Scenario: Log in successfully
  Given I am on Log in page
  Then I fill in Email "nonadmin@myorg.com" and Password "mypassword1234"
  And I click on "Log in" button
  Then I should see "BioSistemika Process"

Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I do not fill in Email and Password
  And I click on button "Log in"
  Then I should see error message "Invalid email or password"

Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I  fill in Email "monday@myorg.com" and Password "monday1234"
  And I click on button "Log in"
  Then I should see error message "Invalid email or password"

Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I  fill in Email "nonadmin@myorg.com" and Password "mypassword123344"
  And I click on button "Log in"
  Then I should see error message "Invalid email or password"

Scenario: Unsuccessful Log in
  Given I am on Log in page
  Then I  fill in Email "monday@myorg.com" and Password "mypassword1234"
  And I click on button "Log in"
  Then I should see error message "Invalid email or password"

Scenario: Successful Log out
  Given home page of a Karli Novak user
  Then I click to avatar
  And I click on "Settings"
  Then I should see message "Logged out successfully."
