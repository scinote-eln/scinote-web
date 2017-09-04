# feature/forgot password.feature
Feature: Forgot password
  I forgot my password
  I would like a new password
  So that I can use sciNote

Background:
  Given the following users is registered:
    | email                   | password           | team
    | nonadmin@myorg.com      | mypassword1234     | BioSistemika Process
  And the following user has got Reset you password email:
    | email                   | password           | team
    | nonadmin@myorg.com      | mypassword1234     | BioSistemika Process

Scenario: User forgot their password and requests for new password
  Given I am on Log in page
  And I click to "Forgot your password?" link
  Then I fill in Email "nonadmin@myorg.com"
  And I click on "Send me reset password instruction" button
  Then I should see "You will receive an email with instructions on how to reset your password in a few minutes." flash message

Scenario: User forgot their password and enters non valid email
  Given I am on Log in page
  And I click to link "Forgot your password?"
  Then I fill in Email "nonuser@myorg.com"
  And I click on "Send me reset password instruction" button
  Then I should see "Email not found." flash message

Scenario: User has got Reset Your Password email and click to link
  Given I have "Reset Your Password" email for user "nonadmin@myorg.com"
  And I click to "RESET PASSWORD" link in email
  Then I should see "Change your password" page

Scenario: User successfully Change password at Change your password page
  Given I am on Change your password page
  Then I fill in New password "mypassword1234" and I fill in Confirm new password "mypassword1234"
  And I click on "Change my password" button
  Then I should see "BioSistemika Process"
  And I should see "Your password has been changed successfully. You are now logged in." flash message

Scenario: User unsuccessfully Change password at Change your password page
  Given I am on Change your password page
  Then I fill in New password "mypassword12344" and I fill in Confirm new password "mypassword1234"
  And I click on "Change my password" button
  Then I should see "Password confirmation doesn't match Password" flash message
