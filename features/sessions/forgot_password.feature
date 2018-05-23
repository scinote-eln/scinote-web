Feature: Forgot password
  I forgot my password
  I would like a new password
  So that I can use SciNote

Background:
  Given the "BioSistemika Process" team exists
  Given the following users are registered
    | email                   | password       | password_confirmation |
    | nonadmin@myorg.com      | mypassword1234 | mypassword1234        |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"

@javascript
Scenario: User forgot their password and requests for new password
  Given I am on reset password page
  Then I fill in "nonadmin@myorg.com" in "#user_email" field
  And I click "Send me reset password instruction" button
  Then I should see "You will receive an email with instructions on how to reset your password in a few minutes." flash message

@javascript
Scenario: User forgot their password and enters non valid email
  Given I am on reset password page
  Then I fill in "nonuser@myorg.com" in "#user_email" field
  And I click "Send me reset password instruction" button
  Then I should see "Email not found"

@javascript
Scenario: User has got Reset Your Password email and click to link
  Given I click on Reset Password link in the reset password email for user "nonadmin@myorg.com"
  Then I should be on Change your password page

@javascript
Scenario: User successfully Change password at Change your password page
  Given I click on Reset Password link in the reset password email for user "nonadmin@myorg.com"
  Then I fill in "newpassword1234" in "#user_password" field
  And I fill in "newpassword1234" in "#user_password_confirmation" field
  And I click "Change my password" button
  Then I should be on homepage
  And I should see "Your password has been changed successfully. You are now logged in." flash message

@javascript
Scenario: User unsuccessfully Change password at Change your password page
  Given I click on Reset Password link in the reset password email for user "nonadmin@myorg.com"
  Then I fill in "newpassword1234" in "#user_password" field
  And I fill in "nosamepassword" in "#user_password_confirmation" field
  And I click "Change my password" button
  Then I should see "Password confirmation doesn't match Password" flash message
