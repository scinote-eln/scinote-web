# feature/protocol step. feature
Feature: Protocol step
  As a member of a project
   want to add/ edit/ delete a step
   want to add/ edit/ delete description to a step
   want to add/ edit/ delete table to a step
   want to add/ edit/ delete file to a step

Background:
Given default screen size
Given the "BioSistemika Process" team exists
Given the following users are registered
   | name        | email              | password       | password_confirmation |
   | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
Given Templates project exists for the "BioSistemika Process" team
And "nonadmin@myorg.com" is signed in with "mypassword1234"

@javascript @wip
Scenario: Unsuccessful add new step to a task
  Given I am on task page of Biosistemika Process team
  And I click "New step" button
  And I click element with css "input.btn:nth-child(2)"
  Then I should see "can't be blank"

@javascript
Scenario: Successful add new step to a task1
  Given I am on task page of Biosistemika Process team
  And I click "New step" button
  And I fill in "PES" in "#step_name" field
  And I fill in "zivali pa so se odpravile dalje po svetu." in "#step_description_textarea_ifr" field
  And I click element with css "#new-step-assets-tab"
  And I attach file "Moon.png" to the drag-n-drop field
  And I click "Add" button
  Then I should see "Moon.png"

@javascript
Scenario: Successful add new step to a task2
  Given I am on task page of Biosistemika Process team
  And I click "New step" button
  And I fill in "NOS" in "#step_name" field
  And I fill in "zivali pa so se odpravile dalje po svetu." in "#step_description_textarea_ifr" field
  And I click element with css "#new-step-assets-tab"
  And I attach file "File.txt" to the drag-n-drop field
  And I click "Add" button
  Then I should see "File.txt"

@javascript
Scenario: Successful add new step to a task3
  Given I am on task page of Biosistemika Process team
  And I click "New step" button
  And I fill in "KIT" in "#step_name" field
  And I fill in "zivali pa so se odpravile dalje po svetu." in "#step_description_textarea_ifr" field
  And I attach file "Star.png" to the drag-n-drop field
  And I click "Add" button
  Then I should see "Star.png"

  @javascript
Scenario: Successful add new step to a task4
  Given I am on task page of Biosistemika Process team
  And I click "New step" button
  And I fill in "BOS" in "#step_name" field
  And I fill in "zivali pa so se odpravile dalje po svetu." in "#step_description_textarea_ifr" field
  And I click element with css "#new-step-tables-tab"
  And I click element with css "#add-table"
  And I fill in "Bos" in ".table_name" field
  And I click "Add" button
  Then I should see "BOS"

@wip
Scenario: Successful reorder Steps
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on down arrow icon of a "LJ ZOO" Step
  And I click on down arrow icon of a "LJ ZOO" Step
  And I click on up arrow icon of a "PES" Step
  Then I should see "PES" step on first position
  Then I should see "ZOO" step on second position

@wip
Scenario: Successful edit Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on "Edit step" icon of "PES"
  And I change "zivali pa so se odpravile dalje po svetu." with "Vse to pa zaradi botra petelina!"
  And I click on "Files" button
  And I click on "Browse to add" button
  And "Open" window is opened
  And I click on "Star.png" File
  And I click on "Open" button
  And I click on "X" of "Moon.png" file
  And I click on "Tables" button
  And I fill in "Seznam pasem" in ".table_name" field
  And I change "Labradorec" with "Bobtail" in "A1" field
  And I fill in "Kraski ovcar" to "D2" Table field
  And I click on "Checklist" button
  And I click on "+Add checklist" button
  And I click on "+Add item" button
  And I click on "+Add item" button
  And I fill in "Seznam pasem" in "Checklist name 1" field
  And I fill in "Buldog" in "Checklist name 2" field
  And I fill in "Lesi" in "Checklist name 3" field
  And I fill in "Hrt" in "Checklist name 4" field
  And I click element with css "input.btn:nth-child(2)"
  Then I should see "PES" edited step

@wip
Scenario: Successful edit Step with reordering checklist items
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on "Edit step" icon of "PES"
  And I click on "Checklist" button
  And I move "Hrt" Checklist item to "1" position
  And I move "Buldog" Checklist item to "3" position
  And I click element with css "input.btn:nth-child(2)"
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
  And I click on Comments of "ZOO"
  And I add "I was on Triglav one summer." in comment field
  And And I click on "paper plane" sign
  Then I should see "I was on Triglav one summer." in Comments list of "ZOO" Step

@wip
Scenario: Unsuccessful add comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on Comments of "ZOO"
  And confirm with ENTER key
  And And I click on "paper plane" sign
  Then I should see "Massage can't be blank" error message under "Comments list" field

@wip
Scenario: Successful edit comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on field of a "I was on Triglav one summer." comment
  And I change "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more."
  And I click on "Save" button
  Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Step

@wip
Scenario: Unsuccessful edit comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on field of a "I was on Triglav one summer." comment
  And I change "I was on Triglav one summer and I do not have plans to go once more." with "I was on Triglav one summer."
  And I click on "X" sign
  Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Step

@wip
Scenario: Unsuccessful delete comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And place mouse on "I was on Triglav one summer and I do not have plans to go once more."
  And I click on "trashcan" button
  And I click on "Cancel" button
  Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Text

@wip
Scenario: Successful delete comment to a Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And place mouse on "I was on Triglav one summer and I do not have plans to go once more."
  And I click on "trashcan" button
  And I click on "OK" button
  Then "I was on Triglav one summer and I do not have plans to go once more." comment is removed from Comments list of "ZOO"

@wip
Scenario: Successful delete Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on "trashcan" icon of "ZOO"
  And I click on "OK" button
  Then I should see " Step 3 successfully deleted." flash message

@wip
Scenario: Successful complete Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on "Complete step" button
  Then I should see "Uncomplete step"

@wip
Scenario: Successful edit completed Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on "Edit step" icon of "PES"
  And I change "Vse to pa zaradi botra petelina!" with "Bezimo, da se nam se kaj ne zgodi!"
  And I click element with css "input.btn:nth-child(2)"
  Then I should see "PES" edited step

@wip
Scenario: Successful uncomplete Step
  Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
  And I click on "Uncomplete step" button
  Then I should see "Complete step"
