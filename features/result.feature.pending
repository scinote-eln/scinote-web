# feature/result. feature
Feature: Result
  As a member of a project
  I want to add/ edit/ delete text results of a task
  I want to add/ edit/ delete table results of a task
  I want to add/ edit/ delete file results of a task

Background:
Given the following users is registered:
 | name                 | email              | password        | team                 | role        |
 |Karli Novak (creator)| nonadmin@myorg.com | mypassword1234  | BioSistemika Process | Administrator|
And the following file:
 | file          | size     |
 | Moon.png      | 0.5 MB   |
 | Star.png      | 0.5 MB   |

 Scenario: Unsuccessful add Text result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Text" button
   And I click on "Add text result" button
   Then I should see Text "can't be blank" red error message
   And I click to "Cancel" button

 Scenario: Successful add text result with Text name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Text" button
   Then I fill in "ZOO" to Name field
   Then I fill in "Živali pa so se odpravile dalje po svetu." to Text field
   And I click on "Add text result" button
   Then I should see "ZOO" Text Result

 Scenario: Successful add Text result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Text" button
   Then I fill in "Vse to pa zaradi botra petelina, bog mu daj zdravje!" to Text field
   And I click on "Add text result" button
   Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!" Text field

 Scenario: Successful edit Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Edit result" icon of a "LJ ZOO" Text task result
   Then I change "LJ ZOO" Name with "ZOO" Name
   Then I change "Živali pa so se odpravile dalje po svetu." Text field with "Vse to pa zaradi botra petelina!" Text field
   And I click on "Update text result" button
   Then I should see "Vse to pa zaradi botra petelina!" Text field

 Scenario: Successful add comment to a Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   Then I add "I was on Triglav one summer." in comment field
   And I click to "+" sign in comment field of a "ZOO" Text result
   Then I should see "I was on Triglav one summer." in Comments list of "ZOO" Text result

 Scenario: Unsuccessful add comment to a Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "+" sign in comment field of a "ZOO" Text result
   Then I should see "can't be blank" red error message under comment field in Comments list of a "ZOO" Text result

 Scenario: Successful edit comment to a Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "ZOO" comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "OK" sign
   Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Text result

 Scenario: Unsuccessful edit comment to a Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "ZOO" comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "Cancel" sign
   Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Text result

 Scenario: Unsuccessful delete comment to a Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
   Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Text result

 Scenario: Successful delete comment to a Text task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
   Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" Text result

 Scenario: Successful archive text result with Text name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive result" icon of a "ZOO" Text task result
   And I click to "OK" button in "Are you sure to archive result?" modal window
   Then I should see "Successfully archived text result in task Control." flash message

 Scenario: Unsuccessful add Table result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Table" button
   And I click on "Add Table result" button
   Then I should see Text "can't be blank" red error message
   And I click to "Cancel" button

 Scenario: Successful add table result with Table name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Table" button
   Then I fill in "ZOO" to Name field
   Then I fill in "Živali pa so se odpravile dalje po svetu." to "A1" Table field
   And I click on "Add table result" button
   Then I should see "ZOO" Table Result

 Scenario: Successful add Table result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Table" button
   Then I fill in "Vse to pa zaradi botra petelina, bog mu daj zdravje!" to "A1" Table field
   And I click on "Add table result" button
   Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!" in "A1" Table field

 Scenario: Successful edit Table task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Edit result" icon of a "LJ ZOO" Table task result
   Then I change "LJ ZOO" Name with "ZOO" Name
   Then I change "Živali pa so se odpravile dalje po svetu." Table field with "Vse to pa zaradi botra petelina!" Table field
   Then I fill in "I was on Triglav one summer" to "B2" Table field
   And I click on "Update table result" button
   Then I should see "I was on Triglav one summer" in "B2" Table field

 Scenario: Successful add comment to a Table task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   Then I add "I was on Triglav one summer." in comment field
   And I click to "+" sign in comment field of a "ZOO" Table result
   Then I should see "I was on Triglav one summer." in Comments list of "ZOO" Table result

 Scenario: Successful edit comment to a Table task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "ZOO" comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "OK" sign
   Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" Table result

 Scenario: Unsuccessful edit comment to a Table task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "ZOO" comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "Cancel" sign
   Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Table result

 Scenario: Unsuccessful delete comment to a Table task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
   Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" Table result

 Scenario: Successful delete comment to a Table task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
   Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" Table result

 Scenario: Successful archive Table result with Table name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive result" icon of a "ZOO" Table task result
   And I click to "OK" button in "Are you sure to archive result?" modal window
   Then I should see "Successfully archived table result in task Control." flash message

 Scenario: Unsuccessful add File result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "File" button
   And I click on "Add file result" button
   Then I should see File "can't be blank" red error message
   And I click to "Cancel" button

 Scenario: Successful add File result with File name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "File" button
   Then I click to "Browse to add" button
   And "Open" window is opened
   And I click to "Moon.png" File
   And I click to "Open" button
   Then I fill in "LJ ZOO" to Name field
   And I click on "Add file result" button
   Then I should see "ZOO" File Result

 Scenario: Successful add File result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "File" button
   Then I click to "Browse to add" button
   And "Open" window is opened
   And I click to "Moon.png" File
   And I click to "Open" button
   And I click on "Add file result" button
   Then I should see "Moon.png" File Result

 Scenario: Successful edit File result with File name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Edit result" icon of a "LJ ZOO" File task result
   Then I click to "Choose Fie" button
   And "Open" window is opened
   And I click to "Star.png" File
   And I click to "Open" button
   Then I change "LJ ZOO" Name with "ZOO" Name
   And I click on "Update file result" button
   Then I should see "LJ ZOO" File Result

 Scenario: Successful add comment to a File task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   Then I add "I was on Triglav one summer." in comment field
   And I click to "+" sign in comment field of a "ZOO" File result
   Then I should see "I was on Triglav one summer." in Comments list of "ZOO" File result

 Scenario: Successful edit comment to a File task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "ZOO" comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "OK" sign
   Then I should see "I was on Triglav one summer and I do not have plans to go once more." in Comments list of a "ZOO" File result

  Scenario: Unsuccessful edit comment to a File task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "ZOO" comment
   And I click to "Edit" in Comment options modal window
   Then I change "I was on Triglav one summer." comment with "I was on Triglav one summer and I do not have plans to go once more." comment
   And I click to "Cancel" sign
   Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" File result

  Scenario: Unsuccessful delete comment to a File task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "Cancel" button in "Are you sure you wish to delete this comment" modal window
   Then I should see "I was on Triglav one summer." in Comments list of a "ZOO" File result

 Scenario: Successful delete comment to a File task result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to down arrow of a "I was on Triglav one summer." comment
   And I click to "Delete" in Comment options modal window
   And I click to "OK" button in "Are you sure you wish to delete this comment" modal window
   Then "I was on Triglav one summer." comment is removed from Comments list of a "ZOO" File result

 Scenario: Successful archive File result with File name
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive result" icon of a "ZOO" File task result
   And I click to "OK" button in "Are you sure to archive result?" modal window
   Then I should see "Successfully archived file result in task Control." flash message

 Scenario: Download archived Text result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "ZOO" Text result
   And I click to down arrow of a "ZOO" Text result
   And I click to "Download" of a Options modal window
   Then I should see "ZOO" Text result is dowloaded

 Scenario: Download archived Table result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "ZOO" Table result
   And I click to down arrow of a "ZOO" Table result
   And I click to "Download" of a Options modal window
   Then I should see "ZOO" Table result is dowloaded

 Scenario: Download archived File result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "ZOO" File result
   And I click to down arrow of a "ZOO" File result
   And I click to "Download" of a Options modal window
   Then I should see "ZOO" File result is dowloaded

 Scenario: Delete archived Text result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "ZOO" Text result
   And I click to down arrow of a "ZOO" Text result
   And I click to "Delete" of a Options modal window
   And I click to "OK" button in "Are you sure to permanently delete result?" modal window
   Then I should see "Sucessfully removed result from task Control." flash message

 Scenario: Delete archived Table result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "ZOO" Table result
   And I click to down arrow of a "ZOO" Table result
   And I click to "Delete" of a Options modal window
   And I click to "OK" button in "Are you sure to permanently delete result?" modal window
   Then I should see "Sucessfully removed result from task Control." flash message

 Scenario: Delete archived File result
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Archive" icon
   Then I should see "ZOO" File result
   And I click to down arrow of a "ZOO" File result
   And I click to "Delete" of a Options modal window
   And I click to "OK" button in "Are you sure to permanently delete result?" modal window
   Then I should see "Sucessfully removed result from task Control." flash message
