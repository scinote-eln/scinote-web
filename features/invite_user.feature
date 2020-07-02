
Feature: Invite people to SciNote
  As an owner of a team
  Want to add new User to my team throughout the SciNote

Background:
 Given default screen size
 Given the following users are registered: 
  |name                 | email              | password        | team                              | role |
  |Karli Novak          | nonadmin@myorg.com | asdf1243        | BioSistemika Process              | admin|
  |Marija Novak         | marija@myorg.com   | asdf1243        | Cell                              | admin|
 #And "nonadmin@myorg.com" is signed in with "asdf1243" - Cannot be used here if you want to access "Sign up" page

@javascript
Scenario: Successful Add team member1
Given "nonadmin@myorg.com" is signed in with "asdf1243"
  And Settings page of BioSistemika Process team of a Karli Novak user 
  And I click "Add team members" button
  And I fill in "lojze@myorg.com" to Invite users to team BioSistemika Process input field
  And confirm with ENTER key to ".bootstrap-tagsinput>input"
  And I click "Invite Users" button
  And I click on "As Normal Users" in Invite dropdown
  Then I should see "lojze@myorg.com  -  User successfully invited to SciNote and team BioSistemika Process as Normal user." massage of "Invitation results:" modal window
  And I click "Close" button
  And I should see "pending"
  And I should see "lojze@myorg.com"

@javascript
Scenario: Successful Add team member2
Given "nonadmin@myorg.com" is signed in with "asdf1243"
  And Settings page of BioSistemika Process team of a Karli Novak user 
  And I click "Add team members" button
  And I fill in "marija@myorg.com" to Invite users to team BioSistemika Process input field
  And confirm with ENTER key to ".bootstrap-tagsinput>input"
  And I click "Invite Users" button
  And I click on "As Normal Users" in Invite dropdown
  Then I should see "marija@myorg.com  -  User was already a member of SciNote - successfully invited to team BioSistemika Process as Normal user." massage of "Invitation results:" modal window
  And I click "Close" button
  And I should see "active"
  And I should see "marija@myorg.com"

@javascript
Scenario: Checking Add team members
  Given "nonadmin@myorg.com" is signed in with "asdf1243"
  And Settings page of BioSistemika Process team of a Karli Novak user 
  And I click "Add team members" button
  And I fill in "marija@myorg.com" to Invite users to team BioSistemika Process input field
  And confirm with ENTER key to ".bootstrap-tagsinput>input"
  And I fill in "lojze@myorg.com" to Invite users to team BioSistemika Process input field
  And confirm with ENTER key to ".bootstrap-tagsinput>input"
  And I click "Invite Users" button
  And I click on "As Normal Users" in Invite dropdown
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
  And I fill in "anicamyorg.com" to Invite users to team BioSistemika Process input field
  And confirm with ENTER key to ".bootstrap-tagsinput>input"
  And I click "Invite Users" button
  And I click on "As Normal Users" in Invite dropdown
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
  And I click on Sign up button
  And I should see "Circle"
  Then I should see "Hi, Karolina"
  #Then I should see "Welcome to SciNote." flash message - Is not implemented in this version
      
#Scenario: Verify invited user does have invitation team - Cannot varify since no e-mail was sent (localhost) 
  #Given Settings page of BioSistemika Process team of a Karli Novak user 
  #Then I should see "Karolina" name in column "Name"

@javascript
Scenario: Unsuccessful Sign up, Password confirmation does not match
Given I visit the sign up page 
  And I fill in "Agata Novakovic" in "#user_full_name" field
  And I fill in "mypassword6666" in "#user_password" field
  And I fill in "agata@myorg.com" in "#user_email" field
  And I fill in "mypassword6665 " in "#user_password_confirmation" field
  And I fill in "Flop" in "#team_name" field
  And I click on Sign up button
  Then I should see "doesn't match Password" error message

@javascript
Scenario: Unsuccessful Sign up, Team name is missing
Given I visit the sign up page 
  And I fill in "Agata Novakovic" in "#user_full_name" field
  And I fill in "mypassword6666" in "#user_password" field
  And I fill in "agata@myorg.com" in "#user_email" field
  And I fill in "mypassword6666" in "#user_password_confirmation" field
  And I click on Sign up button
  Then I should see "is too short (minimum is 2 characters)" error message

