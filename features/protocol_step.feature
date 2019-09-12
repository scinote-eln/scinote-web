# feature/protocol step. feature
Feature: Protocol step
  As a member of a project
  I want to add/ edit/ delete a step
  I want to add/ edit/ delete description to a step
  I want to add/ edit/ delete table to a step
  I want to add/ edit/ delete file to a step

Background:
Given the "BioSistemika Process" team exists
Given the following users are registered
   | name        | email              | password       | password_confirmation |
   | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
Given Demo project exists for the "BioSistemika Process" team
And "nonadmin@myorg.com" is signed in with "mypassword1234"

@wip
Scenario: Unsuccessful add new step to a task
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Add new" button
  And I click on "Add" button
  Then I should see Step name "can't be blank" red error message
  And I click to "Cancel" button

@wip
Scenario: Successful add new step to a task
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Add new" button
  Then I fill in "LJ ZOO" to Step name field
  And I click on "Add" button
  Then I should see "ZOO" step

@wip
Scenario: Successful add new step to a task
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Add new" button
  Then I fill in "ZOO" to Step name field
  And I click on "Add" button
  Then I should see "ZOO" step

@javascript
Scenario: Successful add new step to a task
  Given I'm on the Protocols page of a "qPCR" task
  And I click first "New Step" link
  Then I fill in "PES" in "#step_name" field
  Then I fill in "zivali pa so se odpravile dalje po svetu." in "#step_description_textarea" rich text editor field
  And I click "Files" link
  Then I attach file "Moon.png" to the drag-n-drop field
  Then I attach file "File.txt" to the drag-n-drop field
  Then I attach file "Star.png" to the drag-n-drop field
  Then I click "Tables" link
  Then I click "Add table" link
  Then I fill in "PES" in ".table_name" field
  # Then I fill in "Labradorec" to "A1" Table field
  # Then I fill in "Dalmatinec" to "B2" Table field
  And I click "Add" button
  Then I should see "PES" on "#steps" element
  And I should see "Moon.png" attachment on "PES" step
  And I should see "File.txt" attachment on "PES" step
  And I should see "Star.png" attachment on "PES" step

@wip
Scenario: Successful reorder Steps
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to down arrow icon of a "LJ ZOO" Step
  Then I click to down arrow icon of a "LJ ZOO" Step
  Then I click to up arrow icon of a "PES" Step
  Then I should see "PES" step on first position
  Then I should see "ZOO" step on second position

@wip
Scenario: Successful edit Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Edit step" icon of a "PES" Step
  Then I change "zivali pa so se odpravile dalje po svetu." Description field with "Vse to pa zaradi botra petelina!" Description field
  And I click on "Files" tab
  And I click to "Browse to add" button
  Then "Open" window is opened
  And I click to "Star.png" File
  Then I click to "Open" button
  And I click to "X" of "Moon.png" file
  Then I click on "Tables" tab
  And I fill in "Seznam pasem" to Table title field
  Then I change "Labradorec" cell content with "Bobtail" cell content to "A1" Table field
  And I fill in "Kraski ovcar" to "D2" Table field
  Then I click on "Checklist" tab
  And I click on "+Add checklist" link
  And I click on "+Add item" link
  And I click on "+Add item" link
  Then I fill in "Seznam pasem" to Checklist name field
  And I fill in "Buldog" to Checklist item field
  And I fill in "Lesi" to Checklist item field
  And I fill in "Hrt" to Checklist item field
  And I click on "Add" button
  Then I should see "PES" edited step

@wip
Scenario: Successful edit Step with reordering checklist items
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Edit step" icon of a "PES" Step
  Then I click on "Checklist" tab
  And I move "Hrt" Checklist item to first position
  And I move "Buldog" Checklist item to third position
  And I click on "Add" button
  Then I should see "PES" edited step

@wip
Scenario: Successful check checklist item
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I check "Buldog" Checklist item of a "PES" Step
  And I check "Lesi" Checklist item of a "PES" Step
  Then I should see checked two check boxes

@wip
Scenario: Successful add comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  Then I add "I was on Triglav one summer." in comment field
  And I click to "+" sign in comment field of a "ZOO" Step
  Then I should see "I was on Triglav one summer." in Comments list of "ZOO" Step

@wip
Scenario: Unsuccessful add comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "+" sign in comment field of a "ZOO" Step
  Then I should see "can't be blank" red error message under comment field in Comments list of a "ZOO" Step

@wip
Scenario: Successful edit comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to down arrow of a "ZOO" comment
  And I click to "Edit" in Comment options modal window
  Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
  And I click to "OK" sign
  Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Step

@wip
Scenario: Unsuccessful edit comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to down arrow of a "ZOO" comment
  And I click to "Edit" in Comment options modal window
  Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
  And I click to "Cancel" sign
  Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Step

@wip
Scenario: Unsuccessful delete comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to down arrow of a "I was on Triglav one summer." comment
  And I click to "Delete" in Comment options modal window
  And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
  Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Text

@wip
Scenario: Successful delete comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to down arrow of a "I was on Triglav one summer." comment
  And I click to "Delete" in Comment options modal window
  And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
  Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" Step

@wip
Scenario: Successful delete Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Delete" icon of a "LJ ZOO" Step
  And I click to "OK" button of a "Are you sure to delete step LJ ZOO?" modal window
  Then I should see " Step 3 successfully deleted." flash message

@wip
Scenario: Successful complete Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Complete step" button of a "ZOO" Step
  Then I should see white "Uncomplete step" button

@wip
Scenario: Successful edit completed Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Edit step" icon of a "PES" Step
  Then I change "Vse to pa zaradi botra petelina!" Description field with "Bezimo, da se nam se kaj ne zgodi!" Description field
  And I click on "Add" button
  Then I should see "PES" edited step

@wip
Scenario: Successful uncomplete Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click to "Uncomplete step" button of a "ZOO" Step
  Then I should see "Complete step" button
