Feature: Sign up
  As a new User
  I want to create a new account
  So that I can use SciNote

  Background:
    Given the following users are registered
    | email                   | initials |
    | night.slarker@gmail.com | NS       |
    | tusk@gmail.com          | TU       |
    | juggernaut@gmail.com    | JU       |

  @javascript
  Scenario: Sign up for an existing user
    Given I visit the sign up page
    Then I fill the sign up form with
    | Full name | Email          | Password | Password confirmation | Team name   |
    | Magnus    | tusk@gmail.com | asdf1234 | asdf1234              | SpliceGirls |
    And I click on "Sign up"
    Then I should see "has already been taken"

  @javascript
  Scenario: Sign up for an non-existent user
    Given I visit the sign up page
    Then I fill the sign up form with
    | Full name | Email          | Password | Password confirmation | Team name   |
    | Magnus    | magnus@gmail.com | asdf1234 | asdf1234            | SpliceGirls |
    And I click on "Sign up"
    Then I should be on homepage

  @javascript
  Scenario: Unsuccessful sign up, password confirmation does not match
    Given I visit the sign up page
    Then I fill the sign up form with
    | Full name | Email          | Password | Password confirmation | Team name   |
    | Magnus    | magnus@gmail.com | asdf1234 | asdf1234567         | SpliceGirls |
    And I click on "Sign up"
    Then I should see "doesn't match Password"

  @javascript
  Scenario: Unsuccessful sign up, team name is missing
    Given I visit the sign up page
    Then I fill the sign up form with
    | Full name | Email          | Password | Password confirmation |
    | Magnus    | magnus@gmail.com | asdf1234 | asdf1234            |
    And I click on "Sign up"
    Then I should see "is too short (minimum is 2 characters)"
