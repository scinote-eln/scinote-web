# feature/inventories_delete_item. feature
Feature: Item to column inventory
  As a member of a project
   want to add/ edit/ delete a item to inventory

Background:
Given default screen size2
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name        | email              | password       | password_confirmation |
     | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  Given Demo project exists for the "BioSistemika Process" team
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

#New inventory and new item with TEXT column
Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mačk" to "repository-column-name" field of "Add New Column" modal window
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "Text new" in "tr.editing > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button

@javascript
Scenario: Archive item with TEXT column
  Given I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  Then I should see "Successfully archived items in inventory Torta"

@javascript
Scenario: Restore item with TEXT column
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
Scenario: Delete item with TEXT column
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
