# feature/item_to_column_inventory. feature
Feature: Item to column inventory
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
Scenario: Make/edit TEXT column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mačk" to "repository-column-name" field of "Add New Column" modal window
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in "tr.editing > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "Text new" in "tr.editing > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  And WAIT
  And I make screenshot
  Then I should see "ASDF2"

@javascript
Scenario: Make/edit NUMBER column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Nusurog" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I change "0" with "6" of field "decimals" of "Add New Column" window
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I fill in "11" in ".odd > td:nth-child(7) > div:nth-child(1) > input:nth-child(1)" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

@javascript
Scenario: Make/edit DROPDOWN column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Natupir" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(7)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "input.search-field:nth-child(1)"
  And I click element with css "div.dropdown-option:nth-child(4)"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF2"
  And I make screenshot

@javascript
Scenario: Make/edit CHECKLIST column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Pižmouka" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(8)"
  And I fill in "Meh" in "items-textarea" textarea field
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css "input.search-field:nth-child(1)"
  And I click element with css ".dropdown-option"
  And I click "Save" button
  And WAIT
  Then I should see "ASDF2"
  And I make screenshot

@javascript
Scenario: Make/edit DATE AND TIME column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kuž" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(11)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
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

@javascript
Scenario: Make/edit DATE column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Kojn" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(12)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".calendar-input"
  And I fill in "07/23/2020" in ".calendar-input" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot

@javascript
Scenario: Make/edit TIME column and add an item
  Given I'm on the Inventory page of "Torta"
  And I click "Columns" button
  And I click "Add column" button
  And I fill in "Mučrad" to "repository-column-name" field of "Add New Column" modal window
  And I click element with css "#new-repository-column > div:nth-child(2) > div:nth-child(2) > div:nth-child(2)"
  And I click element with css "div.dropdown-option:nth-child(13)"
  And I click "Save column" button
  And WAIT
  And I'm on the Inventory page of "Torta"
  And I click element with css "#checkbox"
  And I click element with css "#editRepositoryRecord"
  And I fill in "ASDF2" in ".odd > td:nth-child(4) > div:nth-child(1) > input:nth-child(1)" field
  And I click element with css ".time-part"
  And I fill in "04:04" in ".time-part" field
  And I click "Save" button
  Then I should see "ASDF2"
  And I make screenshot