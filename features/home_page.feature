# feature/home page. feature
Feature: Home page
  As a creator of team
   want to create a project
   want to edit, archive project
   want to add user, comment to a project

Background:
Given default screen size
Given the "BioSistemika Process" team exists
Given the "BioSistemika Path" team exists
Given the following users are registered
  | name         | email              | password        | password_confirmation |
  |Karli Novak   | nonadmin@myorg.com | mypassword1234  | mypassword1234        |
  |Marjeta Novak | nonadmin2@myorg.com| mypassword1234  | mypassword1234        |
And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
And "nonadmin2@myorg.com" is in "BioSistemika Process" team as a "normal_user"
And "nonadmin@myorg.com" is in "BioSistemika Path" team as a "normal_user"
And "nonadmin@myorg.com" is signed in with "mypassword1234"

@javascript
 Scenario: Successful create new project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click "All team members" button 
   And I make screenshot
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   Then I should see "Project Mangart successfully created." flash message
   Then I should see "Mangart"

@javascript
 Scenario: Unsuccessful create new project1
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   Then I should see "is too short (minimum is 2 characters)"
   And I click "Cancel" button

@javascript
 Scenario: Unsuccessful create new project2
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   Then I should see "This project name has to be unique inside a team (this includes the archive)"

@javascript
 Scenario: Successful edit project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click to down arrow of a "Mangart" project card
   And I click to "Edit" of a Options modal window
   And I fill in "Golica" in "#project_name" field 
   And I click "Project members only" button
   And I click "Save" button
   Then I should see "Golica"

@javascript
 Scenario: Successful add user to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-users"
   And I click element with css ".manage-users-link"
   And I click element with css ".add-user-form"
   And I click on "User" within dropdown menu
   And I click "Add" button
   And WAIT
   Then I should see "Marjeta Novak"

@javascript
  Scenario: Successful change user role to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-users"
   And I click element with css ".manage-users-link"
   And I click element with css ".add-user-form"
   And I click on "User" within dropdown menu
   And I click "Add" button
   And I click "Change Role" button
   And I click on "Viewer" within dropdown menu
   And WAIT
   Then I should see "Viewer"

@javascript
  Scenario: Successful add new SciNote user to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-users"
   And I click element with css ".manage-users-link"
   And I click element with css "#project-actions-modal > div:nth-child(1) > div:nth-child(1) > div:nth-child(3) > span:nth-child(1) > a:nth-child(1)"
   And I click "Add team members" button
   And I click element with css ".bootstrap-tagsinput"
   And I fill in "random@org.com" in ".bootstrap-tagsinput > input:nth-child(1)" field
   And confirm with ENTER key to ".bootstrap-tagsinput > input:nth-child(1)"
   And I click "Invite Users" button
   And I click element with css "div.btn-group:nth-child(3) > ul:nth-child(2) > li:nth-child(2) > a:nth-child(1)"
   And WAIT
   Then I should see "User successfully invited to SciNote"

@javascript
 Scenario: Unsuccessful adding user to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-users"
   And I click element with css ".manage-users-link"
   And I click element with css "#project-actions-modal > div:nth-child(1) > div:nth-child(1) > div:nth-child(3) > span:nth-child(1) > a:nth-child(1)"
   And I click "Add team members" button
   And I click element with css ".bootstrap-tagsinput"
   And I fill in "random" in ".bootstrap-tagsinput > input:nth-child(1)" field
   And confirm with ENTER key to ".bootstrap-tagsinput > input:nth-child(1)"
   And I click "Invite Users" button
   And I click element with css "div.btn-group:nth-child(3) > ul:nth-child(2) > li:nth-child(2) > a:nth-child(1)"
   And WAIT
   Then I should see "Invalid email."

@javascript
 Scenario: Removing user from a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-users"
   And I click element with css ".manage-users-link"
   And I click element with css "#project-actions-modal > div:nth-child(1) > div:nth-child(1) > div:nth-child(3) > span:nth-child(1) > a:nth-child(1)"
   And I make screenshot
   And I click element with css ".dropdown-teams-user"
   And I click element with css ".open > ul:nth-child(2) > li:nth-child(7) > a:nth-child(1)"
   And I click "Remove" button
   And I make screenshot

@javascript
 Scenario: Successful add comment to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-comment"
   And I fill in "I was on Triglav one summer." in ".smart-text-area" field
   And I make screenshot
   And I click element with css ".new-comment-button"
   Then I should see "I was on Triglav one summer."

@wip
 Scenario: Unsuccessful add comment to a project BUG!!!
   Given I'm on the home page of "Biosistemika Process" team
   And I click on Comments of a "Golica" project card
   And I click on "paper plane" sign
   Then I should see "Message can't be blank" error message 

@wip
 Scenario: Successful edit comment to a project       CANNOT DIFERENTIATE BETWEEN THE NEW AND OLD TEXTAREA
  Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-comment"
   And I fill in "I was on Triglav one summer." in ".smart-text-area" field
   And I make screenshot
   And I click element with css ".new-comment-button"
   And I hover over comment
   And I click element with css ".edit-button"
   And I change "I was on Triglav one summer." with "Sladoled se lahko je vsak dan" in "message" textarea field
   And I click element with css ".save-button"
   Then I should see "Sladoled se lahko je vsak dan"

@javascript
 Scenario: Unsuccessful edit comment to a project
  Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-comment"
   And I fill in "I was on Triglav one summer." in ".smart-text-area" field
   And I make screenshot
   And I click element with css ".new-comment-button"
   And I hover over comment
   And I click element with css ".edit-button"
   And I click element with css ".cancel-button"
   Then I should see "I was on Triglav one summer."

@javascript
 Scenario: Unsuccessful delete comment to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-comment"
   And I fill in "I was on Triglav one summer." in ".smart-text-area" field
   And I make screenshot
   And I click element with css ".new-comment-button"
   And I hover over comment
   And I click element with css ".fa-trash"
   And I click to Cancel on confirm dialog
   Then I should see "I was on Triglav one summer."

@javascript
 Scenario: Successful delete comment to a project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I click element with css ".fa-comment"
   And I fill in "I was on Triglav one summer." in ".smart-text-area" field
   And I make screenshot
   And I click element with css ".new-comment-button"
   And I hover over comment
   And I click element with css ".fa-trash"
   And I click to OK on confirm dialog
   Then I should not see "I was on Triglav one summer."

@javascript
 Scenario: Unsuccessful archived project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I hover over element with css ".panel-heading"
   And I click button with id "dropdownMenu1"
   And I click "Archive" link within dropdown menu
   And I click to Cancel on confirm dialog
   Then I should see "Mangart"

@javascript
 Scenario: Successful archived project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I hover over element with css ".panel-heading"
   And I click button with id "dropdownMenu1"
   And I click "Archive" link within dropdown menu
   And I click to OK on confirm dialog
   Then I should not see "Mangart"

@javascript
 Scenario: Restore archived project
   Given I am on the home page of Biosistemika Process team
   And I click "New Project" button
   And I fill in "Mangart" in "#project_name" field 
   And I click element with css "html body.modal-open div#content-wrapper div#wrapper.container-fluid div#fluid-content.container-fluid div#new-project-modal.modal.in form#new_project.new_project div.modal-dialog div.modal-content div.modal-footer input.btn.btn-primary"
   And I hover over element with css ".panel-heading"
   And I click button with id "dropdownMenu1"
   And I click "Archive" link within dropdown menu
   And I click to OK on confirm dialog
   And I click element with css "#projects-archive-nav-tab"
   And I hover over element with css ".panel-title"
   And I click button with id "dropdownMenu1"
   And I click "Restore" link within dropdown menu
   And I am on the home page of Biosistemika Process team
   Then I should see "Mangart"

