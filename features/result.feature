# feature/result. feature
Feature: Result
  As a member of a project
  I want to add/ edit/ delete text results of a task
  I want to add/ edit/ delete table results of a task
  I want to add/ edit/ delete file results of a task

Background:
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name        | email              | password       | password_confirmation |
     | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  Given Demo project exists for the "BioSistemika Process" team
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

@wip
Scenario: Unsuccessful add Text result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Text" button
 And I click on "Add text result" button
 Then I should see Text "can't be blank" red error message
 And I click to "Cancel" button

@wip
Scenario: Successful add text result with Text name
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Text" button
 Then I fill in "ZOO" to Name field
 Then I fill in "Živali pa so se odpravile dalje po svetu." to Text field
 And I click on "Add text result" button
 Then I should see "ZOO" Text Result

@wip
Scenario: Successful add Text result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Text" button
 Then I fill in "Vse to pa zaradi botra petelina, bog mu daj zdravje!" to Text field
 And I click on "Add text result" button
 Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!" Text field

@wip
Scenario: Successful edit Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Edit result" icon of a "LJ ZOO" Text task result
 Then I change "LJ ZOO" Name with "ZOO" Name
 Then I change "Živali pa so se odpravile dalje po svetu." Text field with "Vse to pa zaradi botra petelina!" Text field
 And I click on "Update text result" button
 Then I should see "Vse to pa zaradi botra petelina!" Text field

@wip
Scenario: Successful add comment to a Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 Then I add "I was on Triglav one summer." in comment field
 And I click to "+" sign in comment field of a "ZOO" Text result
 Then I should see "I was on Triglav one summer." in Comments list of "ZOO" Text result

@wip
Scenario: Unsuccessful add comment to a Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "+" sign in comment field of a "ZOO" Text result
 Then I should see "can't be blank" red error message under comment field in Comments list of a "ZOO" Text result

@wip
Scenario: Successful edit comment to a Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "ZOO" comment
 And I click to "Edit" in Comment options modal window
 Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
 And I click to "OK" sign
 Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Text result

@wip
Scenario: Unsuccessful edit comment to a Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "ZOO" comment
 And I click to "Edit" in Comment options modal window
 Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
 And I click to "Cancel" sign
 Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Text result

@wip
Scenario: Unsuccessful delete comment to a Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "I was on Triglav one summer." comment
 And I click to "Delete" in Comment options modal window
 And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
 Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Text result

@wip
Scenario: Successful delete comment to a Text task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "I was on Triglav one summer." comment
 And I click to "Delete" in Comment options modal window
 And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
 Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" Text result

@wip
Scenario: Successful archive text result with Text name
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive result" icon of a "ZOO" Text task result
 And I click to "OK" button in "Are you sure to archive result?" modal window
 Then I should see "Successfully archived text result in task Control." flash message

@wip
Scenario: Unsuccessful add Table result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Table" button
 And I click on "Add Table result" button
 Then I should see Text "can't be blank" red error message
 And I click to "Cancel" button

@wip
Scenario: Successful add table result with Table name
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Table" button
 Then I fill in "ZOO" to Name field
 Then I fill in "Živali pa so se odpravile dalje po svetu." to "A1" Table field
 And I click on "Add table result" button
 Then I should see "ZOO" Table Result

@wip
Scenario: Successful add Table result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Table" button
 Then I fill in "Vse to pa zaradi botra petelina, bog mu daj zdravje!" to "A1" Table field
 And I click on "Add table result" button
 Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!" in "A1" Table field

@wip
Scenario: Successful edit Table task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Edit result" icon of a "LJ ZOO" Table task result
 Then I change "LJ ZOO" Name with "ZOO" Name
 Then I change "Živali pa so se odpravile dalje po svetu." Table field with "Vse to pa zaradi botra petelina!" Table field
 Then I fill in "I was on Triglav one summer" to "B2" Table field
 And I click on "Update table result" button
 Then I should see "I was on Triglav one summer" in "B2" Table field

@wip
Scenario: Successful add comment to a Table task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 Then I add "I was on Triglav one summer." in comment field
 And I click to "+" sign in comment field of a "ZOO" Table result
 Then I should see "I was on Triglav one summer." in Comments list of "ZOO" Table result

@wip
Scenario: Successful edit comment to a Table task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "ZOO" comment
 And I click to "Edit" in Comment options modal window
 Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
 And I click to "OK" sign
 Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Table result

@wip
Scenario: Unsuccessful edit comment to a Table task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "ZOO" comment
 And I click to "Edit" in Comment options modal window
 Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
 And I click to "Cancel" sign
 Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Table result

@wip
Scenario: Unsuccessful delete comment to a Table task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "I was on Triglav one summer." comment
 And I click to "Delete" in Comment options modal window
 And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
 Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Table result

@wip
Scenario: Successful delete comment to a Table task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "I was on Triglav one summer." comment
 And I click to "Delete" in Comment options modal window
 And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
 Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" Table result

@wip
Scenario: Successful archive Table result with Table name
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive result" icon of a "ZOO" Table task result
 And I click to "OK" button in "Are you sure to archive result?" modal window
 Then I should see "Successfully archived table result in task Control." flash message

@wip
Scenario: Unsuccessful add File result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "File" button
 And I click on "Add file result" button
 Then I should see File "can't be blank" red error message
 And I click to "Cancel" button

@javascript
Scenario: Successful add File result with File name
 Given I'm on the Results page of a "qPCR" task
 And I click "File" link
 Then I attach file "Moon.png" to the drag-n-drop field
 Then I fill in "LJ ZOO" in ".panel-result-attachment-new input" field
 And I click "Add" button
 Then I should see "LJ ZOO" on "#results" element

@javascript
Scenario: Successful add File result
 Given I'm on the Results page of a "qPCR" task
 And I click "File" link
 Then I attach file "File.txt" to the drag-n-drop field
 And I click "Add" button
 Then I should see "File.txt" on "#results" element

@javascript
Scenario: Successful edit File result with File name
 Given I'm on the Results page of a "qPCR" task
 And I click "File" link
 Then I attach file "Moon.png" to the drag-n-drop field
 Then I fill in "LJ ZOO" in ".panel-result-attachment-new input" field
 And I click "Add" button
 And I click edit "LJ ZOO" result icon
 Then I attach a "Star.png" file to "#result_asset_attributes_file" field
 Then I fill in "STAR ZOO" in "#result_name" field
 And I click "Save" button
 Then I should see "STAR ZOO" on "#results" element

@wip
Scenario: Successful add comment to a File task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 Then I add "I was on Triglav one summer." in comment field
 And I click to "+" sign in comment field of a "ZOO" File result
 Then I should see "I was on Triglav one summer." in Comments list of "ZOO" File result

@wip
Scenario: Successful edit comment to a File task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "ZOO" comment
 And I click to "Edit" in Comment options modal window
 Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
 And I click to "OK" sign
 Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" File result

@wip
Scenario: Unsuccessful edit comment to a File task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "ZOO" comment
 And I click to "Edit" in Comment options modal window
 Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
 And I click to "Cancel" sign
 Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" File result

@wip
Scenario: Unsuccessful delete comment to a File task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "I was on Triglav one summer." comment
 And I click to "Delete" in Comment options modal window
 And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
 Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" File result

@wip
Scenario: Successful delete comment to a File task result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to down arrow of a "I was on Triglav one summer." comment
 And I click to "Delete" in Comment options modal window
 And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
 Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" File result

@wip
Scenario: Successful archive File result with File name
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive result" icon of a "ZOO" File task result
 And I click to "OK" button in "Are you sure to archive result?" modal window
 Then I should see "Successfully archived file result in task Control." flash message

@wip
Scenario: Download archived Text result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive" icon
 Then I should see "ZOO" Text result
 And I click to down arrow of a "ZOO" Text result
 And I click to "Download" of a Options modal window
 Then I should see "ZOO" Text result is dowloaded

@wip
Scenario: Download archived Table result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive" icon
 Then I should see "ZOO" Table result
 And I click to down arrow of a "ZOO" Table result
 And I click to "Download" of a Options modal window
 Then I should see "ZOO" Table result is dowloaded

@wip
Scenario: Download archived File result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive" icon
 Then I should see "ZOO" File result
 And I click to down arrow of a "ZOO" File result
 And I click to "Download" of a Options modal window
 Then I should see "ZOO" File result is dowloaded

@wip
Scenario: Delete archived Text result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive" icon
 Then I should see "ZOO" Text result
 And I click to down arrow of a "ZOO" Text result
 And I click to "Delete" of a Options modal window
 And I click to "OK" button in "Are you sure to permanently delete result?" modal window
 Then I should see "Sucessfully removed result from task Control." flash message

@wip
Scenario: Delete archived Table result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive" icon
 Then I should see "ZOO" Table result
 And I click to down arrow of a "ZOO" Table result
 And I click to "Delete" of a Options modal window
 And I click to "OK" button in "Are you sure to permanently delete result?" modal window
 Then I should see "Sucessfully removed result from task Control." flash message

@wip
Scenario: Delete archived File result
 Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
 And I click to "Archive" icon
 Then I should see "ZOO" File result
 And I click to down arrow of a "ZOO" File result
 And I click to "Delete" of a Options modal window
 And I click to "OK" button in "Are you sure to permanently delete result?" modal window
 Then I should see "Sucessfully removed result from task Control." flash message
