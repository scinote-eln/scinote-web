# feature/inventories. feature
Feature: Inventories
  As a member of a project
   want to add/ edit/ delete an inventory
   want to add / change columns

Background:
Given default screen size2
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name        | email              | password       | password_confirmation |
     | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  Given Demo project exists for the "BioSistemika Process" team
  And "nonadmin@myorg.com" is signed in with "mypassword1234"


@javascript
Scenario: Create new inventory
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  Then I should see "Inventory Torta successfully created."

@javascript
Scenario: Edit Samples inventory
  Given I'm on the Inventory page
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Edit" button
  And I change "Samples" with "Neki" of field "repository_name" of "Edit inventory: Samples" window
  And I click element with css "input.btn"
  Then I should see "Neki"

@javascript
Scenario: Duplicate Samples inventory
  Given I'm on the Inventory page
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Duplicate" button
  And I change "Samples" with "Samples2" of field "repository_name" of "Copy inventory: Samples" window
  And I click element with css "input.btn"
  And WAIT
  Then I should see "Samples2"

@javascript
Scenario: Archive inventory
  Given I'm on the Inventory page
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  Then I should not see "Samples"

@javascript
Scenario: Delete inventory
  Given I'm on the Inventory page
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Delete" button
  And WAIT
  And I click element with css "#confirm-repo-delete"
  Then I should see "inventory was successfully deleted"

@javascript
Scenario: Restore inventory
  Given I'm on the Inventory page
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Archive" button
  And I click "View" button
  And I click element with css ".view-switch-archived"
  And WAIT
  And I click element with css "#\31  > td:nth-child(1) > div:nth-child(1)"
  And I click "Restore" button
  And WAIT
  Then I should see "Inventories were successfully restored!"

@javascript
Scenario: Make new TEXT column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mačk" to "repository-column-name" field of "Add New Column" modal window
  And I click "Save column" button
  And WAIT
  Then I should see "Mačk"

@javascript
Scenario: Edit TEXT column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mačk" to "repository-column-name" field of "Add New Column" modal window
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Mačk" with "Bobr" of field "repository-column-name" of "Edit Mačk Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete TEXT column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mačk" to "repository-column-name" field of "Add New Column" modal window
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Mačk"

@javascript
Scenario: Make new NUMBER column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Nusurog" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I change "0" with "6" of field "decimals" of "Add New Column" window
  And I click "Save column" button
  And WAIT
  Then I should see "Nusurog"  

@javascript
Scenario: Edit NUMBER column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Nusurog" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I change "0" with "6" of field "decimals" of "Add New Column" window
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Nusurog" with "Bobr" of field "repository-column-name" of "Edit Nusurog Column" window
  And I change "6" with "7" of field "decimals" of "Edit Nusurog Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete NUMBER column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Nusurog" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I change "0" with "6" of field "decimals" of "Add New Column" window
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Nusurog"

@javascript
Scenario: Make new FILE column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kmela" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(5)"
  And I click "Save column" button
  And WAIT
  Then I should see "Kmela"  

@javascript
Scenario: Edit FILE column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kmela" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(5)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Kmela" with "Bobr" of field "repository-column-name" of "Edit Kmela Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete FILE column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kmela" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(5)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Kmela"

@javascript
Scenario: Make new DROPDOWN column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Natupir" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(7)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  Then I should see "Natupir"  

@javascript
Scenario: Edit DROPDOWN column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Natupir" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(7)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Natupir" with "Bobr" of field "repository-column-name" of "Edit Natupir Column" window
  And I change "Meh" with "Neh" in "items-textarea" textarea field
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete DROPDOWN column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Natupir" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(7)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Natupir"

@javascript
Scenario: Make new CHECKLIST column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pižmouka" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(8)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  Then I should see "Pižmouka"  

@javascript
Scenario: Edit CHECKLIST column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pižmouka" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(8)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Pižmouka" with "Bobr" of field "repository-column-name" of "Edit Pižmouka Column" window
  And I change "Meh" with "Neh" in "items-textarea" textarea field
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete CHECKLIST column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pižmouka" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(8)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Pižmouka"

@javascript
Scenario: Make new STATUS column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pteln" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(9)"
  And I click "Save column" button
  And WAIT
  Then I should see "Pteln"  

@javascript
Scenario: Edit STATUS column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pteln" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(9)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Pteln" with "Bobr" of field "repository-column-name" of "Edit Pteln Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete STATUS column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pteln" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(9)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Pteln"

@javascript
Scenario: Make new DATE AND TIME column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kuž" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(11)"
  And I click "Save column" button
  And WAIT
  Then I should see "Kuž"  

@javascript
Scenario: Edit DATE AND TIME column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kuž" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(11)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Kuž" with "Bobr" of field "repository-column-name" of "Edit Kuž Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete DATE AND TIME column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kuž" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(11)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Kuž"

@javascript
Scenario: Make new DATE column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kojn" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(12)"
  And I click "Save column" button
  And WAIT
  Then I should see "Kojn"  

@javascript
Scenario: Edit DATE column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kojn" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(12)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Kojn" with "Bobr" of field "repository-column-name" of "Edit Kojn Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete DATE column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kojn" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(12)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Kojn"

@javascript
Scenario: Make new TIME column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mučrad" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(13)"
  And I click "Save column" button
  And WAIT
  Then I should see "Mučrad"  

@javascript
Scenario: Edit TIME column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mučrad" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(13)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(1)"
  And I change "Mučrad" with "Bobr" of field "repository-column-name" of "Edit Mučrad Column" window
  And I click "Update column" button
  And WAIT
  Then I should see "Bobr"

@javascript
Scenario: Delete TIME column
  Given I'm on the Inventory page of "Samples"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mučrad" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(13)"
  And I click "Save column" button
  And WAIT
  And I hover over element with css "li.col-list-el:nth-child(9)"
  And I click element with css "li.col-list-el:nth-child(9) > span:nth-child(5) > button:nth-child(2)"
  And I click "Delete" button
  And WAIT
  Then I should not see "Mučrad"

#inventories_items
@wip 
Scenario: Add an ITEM to inventory
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF1"

#inventories_items
@wip 
Scenario: Edit an ITEM to inventory
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".text-field > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF2"

#inventories_items
@wip 
Scenario: Archive an ITEM to inventory
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  Then I should see "Successfully archived items in inventory Torta"

#inventories_items
@wip 
Scenario: Restore an ITEM to inventory
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
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

#inventories_items
@wip 
Scenario: Delete an ITEM to inventory
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
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
 
#inventories_item_to_column
@wip
Scenario: Make TEXT column and add an item
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
  And WAIT
  Then I should see "ASDF1"

#inventories_item_to_column
@wip
Scenario: Edit item with TEXT column
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
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "Text edit" in ".odd > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make NUMBER column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Nusurog" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I change "0" with "6" of field "decimals" of "Add New Column" window
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "10" in "tr.editing > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Edit item with NUMBER column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Nusurog" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I change "0" with "6" of field "decimals" of "Add New Column" window
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "10" in "tr.editing > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "11" in ".odd > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#not working yet
@wip
Scenario: Make FILE column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kmela" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(5)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".file-upload-button"
  And I wait for 3 sec
  And I make screenshot
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  #And I make screenshot

#not working yet
@wip
Scenario: Edit item with FILE column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kmela" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(5)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I attach a "Moon.png" file to ".file-editing" field
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "11" in ".odd > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make DROPDOWN column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Natupir" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(7)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "input.search-field:nth-child(1)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Edit item with DROPDOWN column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Natupir" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(7)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "input.search-field:nth-child(1)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".tag-label"
  And I click element with css "div.dropdown-option:nth-child(3)"
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make CHECKLIST column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pižmouka" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(8)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "input.search-field:nth-child(1)"
  And I click element with css ".dropdown-option"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make edit item with CHECKLIST column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pižmouka" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(8)"
  And I fill in "Meh Heh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "input.search-field:nth-child(1)"
  And I make screenshot
  And I click element with css ".div.dropdown-option:nth-child(2)"
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "#\31 0 > td:nth-child(7) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(3)"
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make DATE AND TIME column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kuž" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(11)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in ".text-field > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I click element with css ".time-part"
  And I click element with css ".fa-clock"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  And I make screenshot

#inventories_item_to_column  
@wip
Scenario: Edit item with DATE AND TIME column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kuž" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(11)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in ".text-field > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I click element with css ".time-part"
  And I click element with css ".fa-clock"
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I fill in "07/23/2020" in ".calendar-input" field
  And I click element with css ".time-part"
  And I fill in "04:04" in ".time-part" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make DATE column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kojn" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(12)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in ".text-field > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Edit item with DATE column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kojn" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(12)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in ".text-field > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I fill in "07/23/2020" in ".calendar-input" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Make TIME column and add an item
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mučrad" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(13)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in ".text-field > input:nth-child(1)" field
  And I click element with css ".time-part"
  And I click element with css ".fa-clock"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF1"
  And I make screenshot

#inventories_item_to_column
@wip
Scenario: Edit item with TIME column
  Given I'm on the Inventory page
  And I click "New Inventory" button
  And I fill in "Torta" to "repository_name" field of "Create new inventory" modal window
  And I click element with css ".btn-success"
  And WAIT
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mučrad" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(13)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click "New item" button
  And I fill in "ASDF1" in ".text-field > input:nth-child(1)" field
  And I click element with css ".time-part"
  And I click element with css ".fa-clock"
  And I click "Save" button
  And WAIT
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".time-part"
  And I fill in "04:04" in ".time-part" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

#inventories_delete_item
@wip
Scenario: ARCHIVE item with TEXT column
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
  And WAIT
  And I click element with css "#checkbox"
  And I click "Archive" button
  And WAIT
  Then I should see "Successfully archived items in inventory Torta"

#inventories_delete_item
@wip
Scenario: RESTORE item with TEXT column
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
  And WAIT
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

#inventories_delete_item
@wip
Scenario: DELETE item with TEXT column
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
  And WAIT
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