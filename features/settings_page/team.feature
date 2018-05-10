Feature: Team settings
  As a creator of a team
  I want to be able to change team name, team description and user roles
  So that I can manage my team

  Background:
    Given the "BioSistemika Process" team exists
    Given the following users are registered
      | email                   | password           | password_confirmation | full_name     | initials  |
      | karli@myorg.com         | mypassword1234     | mypassword1234        | Karli Novak   | KN        |
      | marija@myorg.com        | mypassword5555     | mypassword5555        | Marija Novak  | MN        |
      | suazana@myorg.com       | mypassword6666     | mypassword6666        | Suazana Novak | SN        |
    And "karli@myorg.com" is in "BioSistemika Process" team as a "admin"
    And "marija@myorg.com" is in "BioSistemika Process" team as a "normal_user"
    And "suazana@myorg.com" is in "BioSistemika Process" team as a "guest"
    And "karli@myorg.com" is signed in with "mypassword1234"

  @javascript
  Scenario: Successfully changes team name
    Given I'm on "BioSistemika Process" team settings page
    Then I click on team title
    And I change "BioSistemika Process" with "BioSistemika Process Company" in "team-name-modal" input field
    Then I click "Save" button
    And I should see "BioSistemika Process Company" on "#team-name" element

  @javascript
  Scenario: Successfully adds team description
    Given I'm on "BioSistemika Process" team settings page
    Then I click on ".description-label" element
    And I fill in "I was on Triglav one summer." in "team_description" textarea field
    Then I click "Save" button
    And I should see "I was on Triglav one summer." on ".description-label" element

  @javascript
  Scenario: Successfully changes team description
    Given I'm on "BioSistemika Process" team settings page
    Then I click on ".description-label" element
    And I change "Lorem ipsum dolor sit amet, consectetuer adipiscing eli." with "I was on Triglav one summer." in "team_description" textarea field
    Then I click "Save" button
    And I should see "I was on Triglav one summer." on ".description-label" element

  @javascript
  Scenario: Successfully changes user role
    Given I'm on "BioSistemika Process" team settings page
    Then I click on "marija@myorg.com" action button within Team members table
    And I click "Guest" link within "marija@myorg.com" actions dropdown within Team members table
    Then I should see "Guest" in Role column of "marija@myorg.com" within Team members table

  @javascript
  Scenario: Successfully changes user role
    Given I'm on "BioSistemika Process" team settings page
    Then I click on "suazana@myorg.com" action button within Team members table
    And I click "Normal user" link within "suazana@myorg.com" actions dropdown within Team members table
    Then I should see "Normal user" in Role column of "suazana@myorg.com" within Team members table

  @javascript
  Scenario: Successfully changes user role
    Given I'm on "BioSistemika Process" team settings page
    Then I click on "marija@myorg.com" action button within Team members table
    And I click "Administrator" link within "marija@myorg.com" actions dropdown within Team members table
    Then I should see "Administrator" in Role column of "marija@myorg.com" within Team members table

  @javascript
  Scenario: Successfully removes user
    Given I'm on "BioSistemika Process" team settings page
    Then I click on "suazana@myorg.com" action button within Team members table
    And I click "Remove" link within "suazana@myorg.com" actions dropdown within Team members table
    And I should see "Are you sure you wish to remove user Suazana Novak from team BioSistemika Process?"
    Then I click "Remove" button
    Then I should not see "suazana@myorg.com" in Team members table
