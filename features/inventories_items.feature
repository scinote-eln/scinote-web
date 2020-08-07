# feature/item_to_inventory. feature
Feature: Item to inventory
  As a member of a project
   want to add/ edit/ delete aitems to inventory

Background:
Given default screen size2
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name        | email              | password       | password_confirmation |
     | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  Given Demo project exists for the "BioSistemika Process" team
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

#New inventory and new item
  Given I'm on the Inventory page 
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT

@javascript
Scenario: Edit item
  Given I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".text-field > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF2"

@javascript
Scenario: Archive item
  Given I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  Then I should see "Successfully archived items in inventory Torta"

@javascript
Scenario: Restore item
  Given I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#checkbox"
  And I click "Restore" button
  And WAIT
  Then I should see "Successfully restored items in inventory Torta"

@javascript
Scenario: Delete item
  Given I'm on the Inventory page of "Torta"
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
  Then I should see "1 item(s) successfully deleted."