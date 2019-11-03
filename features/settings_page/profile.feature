Feature: Settings
  As a user
  I want to be able to change Profile data for my account
  So that I have a my prefered settings

Background:
 Given the "BioSistemika Process" team exists
 Given the following users are registered
  | email                   | password           | password_confirmation | full_name   | initials  |
  | nonadmin@myorg.com      | mypassword1234     | mypassword1234        | Karli Novak | KN        |
 And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "normal_user"
 And "nonadmin@myorg.com" is signed in with "mypassword1234"

 @javascript @wip
 Scenario: Successful navigate to profile page
   Given I'm on the home page of "BioSistemika Process" team
   And I click on Avatar
   And I click "Settings" link within "#user-account-dropdown"
   Then I should see "My profile"

@javascript
Scenario: Successful upload avatar image
  Given I'm on the profile page
  Then I click on image within ".avatar-container" element
  And I attach a "Star.png" file to "#raw_avatar" field
  Then I click "Save" button
  And I should see "Your account has been updated successfully" flash message

@javascript
Scenario: Successfully changes user full name
  Given I'm on the profile page
  Then I click on ".settings-page-full-name" element
  And I fill in "Karli Novak Novakovic" in ".settings-page-full-name" input field
  Then I click on ".save-button" element
  And I should see "Karli Novak Novakovic" on ".settings-page-full-name" element

@javascript
Scenario: Unsuccessfully changes user initials, text is too long
  Given I'm on the profile page
  Then I click on ".settings-page-initials" element
  And I fill in "KNOCK" in ".settings-page-initials" input field
  Then I click on ".save-button" element
  And I should see "is too long (maximum is 4 characters)" error message

@javascript
Scenario: Successfully changes user initials
  Given I'm on the profile page
  Then I click on ".settings-page-initials" element
  And I fill in "KN" in ".settings-page-initials" input field
  Then I click on ".save-button" element
  And I should see "KN" on ".settings-page-initials" element

@javascript
Scenario: Successfully changes user email
  Given I'm on the profile page
  Then I click on Edit on ".settings-page-email" input field
  And I change "nonadmin@myorg.com" with "user@myorg.com" email
  And I fill in "mypassword1234" in "#edit-email-current-password" field of ".settings-page-email" form
  Then I click "Save" button
  And I should see "user@myorg.com" in ".settings-page-email" input field

@javascript
Scenario: Unsuccessful Password Change, password is too short
  Given I'm on the profile page
  Then I click on Edit on ".settings-page-change-password" input field
  And I fill in "mypassword1234" in "#edit-password-current-password" field of ".settings-page-change-password" form
  And I fill in "mypass" in "#user_password" field of ".settings-page-change-password" form
  And I fill in "mypass" in "#user_password_confirmation" field of ".settings-page-change-password" form
  Then I click "Save" button
  And I should see "is too short (minimum is 8 characters)"

@javascript
Scenario: Unsuccessful Password Change, passwords does not match
  Given I'm on the profile page
  Then I click on Edit on ".settings-page-change-password" input field
  And I fill in "mypassword1234" in "#edit-password-current-password" field of ".settings-page-change-password" form
  And I fill in "mypassword5678" in "#user_password" field of ".settings-page-change-password" form
  And I fill in "mypassword56788" in "#user_password_confirmation" field of ".settings-page-change-password" form
  Then I click "Save" button
  And I should see "doesn't match"

@javascript
Scenario: Unsuccessful Password Change, current password is invalid
  Given I'm on the profile page
  Then I click on Edit on ".settings-page-change-password" input field
  And I fill in "mypassword123" in "#edit-password-current-password" field of ".settings-page-change-password" form
  And I fill in "mypassword5678" in "#user_password" field of ".settings-page-change-password" form
  And I fill in "mypassword5678" in "#user_password_confirmation" field of ".settings-page-change-password" form
  Then I click "Save" button
  And I should see "is invalid"

@javascript
Scenario: Successful Password Change
  Given I'm on the profile page
  Then I click on Edit on ".settings-page-change-password" input field
  And I fill in "mypassword1234" in "#edit-password-current-password" field of ".settings-page-change-password" form
  And I fill in "mypassword5678" in "#user_password" field of ".settings-page-change-password" form
  And I fill in "mypassword5678" in "#user_password_confirmation" field of ".settings-page-change-password" form
  Then I click "Save" button
  And I should see "Password successfully updated." flash message
