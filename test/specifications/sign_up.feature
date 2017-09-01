# feature/sign up.feature
Feature: Sign up
  As a new User
  I want to Sign up as a new User
  I want to create a new account

Background:
 Given the following users is registered:
  | email                   | password           | team
  | nonadmin@myorg.com      | mypassword1234     | BioSistemika Process

Scenario: Successful Sign up
  Given I am on Sign up page
  Then I fill the Sign up form with
   | Full name | Email             | Password       | Password confirmation | Team name   |
   | Karli    | nonuser@myorg.com | mypassword1234 | mypassword1234        | BioSistemika Process |
  And I click on reCAPTCHA.
  And I click on "Sign up" button
  Then I should see "BioSistemika Process"
  Then I should see "Hi, Karli" nex to the avatar
  And I should get a Gamification pop up message "Welcome to sciNote."

 Scenario: Unsuccessful Sign up, Password confirmation does not match
   Given I am on Sign up page
   Then I fill the Sign up form with
   | Full name | Email             | Password       | Password confirmation | Team name   |
   | Karli    | nonuser@myorg.com | mypassword1234 | mypassword123344        | BioSistemika Process |
   And I click on reCAPTCHA.
   And I click on "Sign up" button
   Then I should see "doesn't match Password" error message under "Password confirmation" field

Scenario: Unsuccessful Sign up, Team name is missing
   Given I am on Sign up page
   Then I fill the Sign up form with
   | Full name | Email             | Password       | Password confirmation |
   | Karli    | nonuser@myorg.com | mypassword1234 | mypassword123344        |
   And I click on reCAPTCHA.
   And I click on "Sign up" button
   Then I should see "is too short (minimum is 2 characters)" error message under "Team name" field

Scenario: Unsuccessful Sign up, reCAPTCHA is missing
   Given I am on Sign up page
   Then I fill the Sign up form with
    | Full name | Email             | Password       | Password confirmation | Team name   |
    | Karli    | nonuser@myorg.com | mypassword1234 | mypassword1234        | BioSistemika Process |
   And I click on "Sign up" button
   Then I should see "reCAPTCHA verification failed, please try again." error message under "recaptcha" field

Scenario: Unsuccessful Sign up, Email has already been taken
   Given I am on Sign up page
   Then I fill the Sign up form with
    | Full name | Email             | Password       | Password confirmation | Team name   |
    | Karli    | nonadmin@myorg.com | mypassword1234 | mypassword1234        | BioSistemika Process |
   And I click on "Sign up" button
   Then I should see "has already been taken" error message under Email field
