# feature/smart_anotations. feature
Feature: Smart anotations
  Add smart anotations:
  - archive, delete item
  - archive, delete inventory

Background:
Given default screen size2
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name        | email              | password       | password_confirmation |
     | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  Given Demo project exists for the "BioSistemika Process" team
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

  #New inventory and item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "an" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button


@javascript
Scenario: Add smart anotations for inventories - Protocol discription
  Given I'm on the Protocols page of a "Experiment design" task
  And I click element with css "#my_module_description_view"
  And confirm with ENTER key to "#my_module_description_textarea_ifr"
  And I fill in "[#an~rep_item~6]" in "#my_module_description_textarea" rich text editor field
  And I click element with css ".tinymce-save-button"
  And WAIT
  Then I should see "Tor an"

@javascript
Scenario: Archive and item in inventory - Protocol discription
  Given I'm on the Protocols page of a "Experiment design" task
  And I click element with css "#my_module_description_view"
  And confirm with ENTER key to "#my_module_description_textarea_ifr"
  And I fill in "[#an~rep_item~6]" in "#my_module_description_textarea" rich text editor field
  And I click element with css ".tinymce-save-button"
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  And I'm on the Protocols page of a "Experiment design" task
  And WAIT
  Then I should see "Tor an (archived)"
 
@javascript
Scenario: Delete an item in inventory - Protocol discription
  Given I'm on the Protocols page of a "Experiment design" task
  And I click element with css "#my_module_description_view"
  And confirm with ENTER key to "#my_module_description_textarea_ifr"
  And I fill in "[#an~rep_item~6]" in "#my_module_description_textarea" rich text editor field
  And I click element with css ".tinymce-save-button"
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#checkbox"
  And I click "Delete" button
  And I click element with css ".btn-danger"
  And WAIT
  And I'm on the Protocols page of a "Experiment design" task
  And WAIT
  And I make screenshot
  Then I should see "Inv an (deleted)"

@javascript
Scenario: Archive an inventory - Protocol discription
  Given I'm on the Protocols page of a "Experiment design" task
  And I click element with css "#my_module_description_view"
  And confirm with ENTER key to "#my_module_description_textarea_ifr"
  And I fill in "[#an~rep_item~6]" in "#my_module_description_textarea" rich text editor field
  And I click element with css ".tinymce-save-button"
  And WAIT
  And I'm on the Inventory page
  And I click element with css "#\32  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  And WAIT
  And I'm on the Protocols page of a "Experiment design" task
  And WAIT
  Then I should see "Tor an (archived)"

@javascript
Scenario: Delete an inventory - Protocol discription
  Given I'm on the Protocols page of a "Experiment design" task
  And I click element with css "#my_module_description_view"
  And confirm with ENTER key to "#my_module_description_textarea_ifr"
  And I fill in "[#an~rep_item~6]" in "#my_module_description_textarea" rich text editor field
  And I click element with css ".tinymce-save-button"
  And WAIT
  And I'm on the Inventory page
  And I click element with css "#\32  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#\32  > td:nth-child(1) > div:nth-child(1)"
  And I click "Delete" button
  And WAIT
  And I click element with css "#confirm-repo-delete"
  And WAIT
  And I'm on the Protocols page of a "Experiment design" task
  Then I should see "Inv an (deleted)"

@javascript
Scenario: Add smart anotations for inventories - Project comment
  Given I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And I fill in "[#an~rep_item~6]" in "message" textarea field
  And I click "fa-paper-plane" icon
  And WAIT
  Then I should see "Tor an"

@javascript
Scenario: Archive and item in inventory - Project comment
  Given I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And I fill in "[#an~rep_item~6]" in "message" textarea field
  And I click "fa-paper-plane" icon
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  And I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And WAIT
  Then I should see "Tor an (archived)"
 
@javascript
Scenario: Delete an item in inventory - Project comment
  Given I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And I fill in "[#an~rep_item~6]" in "message" textarea field
  And I click "fa-paper-plane" icon
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#checkbox"
  And I click "Delete" button
  And I click element with css ".btn-danger"
  And WAIT
  And I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And WAIT
  And I make screenshot
  Then I should see "Inv an (deleted)"

@javascript
Scenario: Archive an inventory - Project comment
  Given I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And I fill in "[#an~rep_item~6]" in "message" textarea field
  And I click "fa-paper-plane" icon
  And WAIT
  And I'm on the Inventory page
  And I click element with css "#\32  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  And WAIT
  And I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And WAIT
  Then I should see "Tor an (archived)"

@javascript
Scenario: Delete an inventory - Project comment
  Given I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And I fill in "[#an~rep_item~6]" in "message" textarea field
  And I click "fa-paper-plane" icon
  And WAIT
  And I'm on the Inventory page
  And I click element with css "#\32  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#\32  > td:nth-child(1) > div:nth-child(1)"
  And I click "Delete" button
  And WAIT
  And I click element with css "#confirm-repo-delete"
  And WAIT
  And I'm on the projects page of "BioSistemika Process" team
  And I click element with css "li.pull-right:nth-child(2) > a:nth-child(1)"
  And WAIT
  And I make screenshot
  Then I should see "Inv an (deleted)"
