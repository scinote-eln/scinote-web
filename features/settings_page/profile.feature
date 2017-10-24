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
 And is signed in with "nonadmin@myorg.com", "mypassword1234"

 @javascript
 Scenario: Successful navigate to profile page
   Given I'm on the home page of "BioSistemika Process" team
   And I click on Avatar
   And I click "Settings" link within "user-account-dropdown"
   Then I should see "My Profile"

@javascript
Scenario: Unsuccessful avatar image upload, file is too big
  Given I'm on the profile page
  Then I click on image within ".avatar-container" element
  And I attach a "Moon.png" file to "user_avatar_input" field
  Then I click "Upload" button
  And I should see "Avatar file size must be less than 0.2 MB" error message under "user_avatar_input" field

@javascript
Scenario: Unsuccessful avatar image upload, file is invalid
  Given I'm on the profile page
  Then I click on image within ".avatar-container" element
  And I attach a "File.txt" file to "user_avatar_input" field
  Then I click "Upload" button
  And I should see "Avatar content type is invalid" error message under "user_avatar_input" field

@javascript
Scenario: Successful upload avatar image
  Given I'm on the profile page
  Then I click on image within ".avatar-container" element
  And I attach a "Star.png" file to "user_avatar_input" field
  Then I click "Upload" button
  And I should see "Your account has been updated successfully" flash message

@javascript
Scenario: Successfully changes user full name
  Given I'm on the profile page
  Then I click on Edit on "settings_page.full_name" input field
  And I fill in "Karli Novak Novakovic" in "settings_page.full_name" input field
  Then I click "Update" button
  And I should see "Karli Novak Novakovic" in "settings_page.full_name" input field

@javascript
Scenario: Unsuccessfully changes user initials, text is too long
  Given I'm on the profile page
  Then I click on Edit on "settings_page.initials" input field
  And I fill in "KNOCK" in "settings_page.initials" input field
  Then I click "Update" button
  And I should see "is too long (maximum is 4 characters)" error message under "settings_page.initials" field

@javascript
Scenario: Successfully changes user initials
  Given I'm on the profile page
  Then I click on Edit on "settings_page.initials" input field
  And I fill in "KN" in "settings_page.initials" input field
  Then I click "Update" button
  And I should see "KN" in "settings_page.initials" input field

@javascript
Scenario: Successfully changes user email
  Given I'm on the profile page
  Then I click on Edit on "settings_page.email" input field
  And I change "nonadmin@myorg.com" with "user@myorg.com" email
  And I fill in "mypassword1234" in Current password field
  Then I click "Update" button
  And I should see "user@myorg.com" in "settings_page.email" input field

@javascript
Scenario: Unsuccessful Password Change, password is too short
  Given I'm on the profile page
  Then I click on Edit on "settings_page.change_password" input field
  And I fill in "mypassword1234" in Current password field
  And I fill in "mypass" in New password field
  And I fill in "mypass" in New password confirmation field
  Then I click "Update" button
  And I should see "is too short (minimum is 8 characters)"

@javascript
Scenario: Unsuccessful Password Change, passwords does not match
  Given I'm on the profile page
  Then I click on Edit on "settings_page.change_password" input field
  And I fill in "mypassword1234" in Current password field
  And I fill in "mypassword5678" in New password field
  And I fill in "mypassword56788" in New password confirmation field
  Then I click "Update" button
  And I should see "Passwords don't match"

@javascript
Scenario: Unsuccessful Password Change, current password is invalid
  Given I'm on the profile page
  Then I click on Edit on "settings_page.change_password" input field
  And I fill in "mypassword123" in Current password field
  And I fill in "mypassword5678" in New password field
  And I fill in "mypassword5678" in New password confirmation field
  Then I click "Update" button
  And I should see "Password is invalid!"

@javascript
Scenario: Successful Password Change
  Given I'm on the profile page
  Then I click on Edit on "settings_page.change_password" input field
  And I fill in "mypassword1234" in Current password field
  And I fill in "mypassword5678" in New password field
  And I fill in "mypassword5678" in New password confirmation field
  Then I click "Update" button
  And I should see "Your account has been updated successfully" flash message
