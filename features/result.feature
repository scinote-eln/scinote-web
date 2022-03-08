# feature/result. feature
Feature: Result
  As a member of a project
  want to add/ edit/ delete text results of a task
  want to add/ edit/ delete table results of a task
  want to add/ edit/ delete file results of a task

Background:
  Given default screen size2
  Given the "BioSistemika Process" team exists
  Given the following users are registered
     | name        | email              | password       | password_confirmation |
     | Karli Novak | nonadmin@myorg.com | mypassword1234 | mypassword1234 |
  And "nonadmin@myorg.com" is in "BioSistemika Process" team as a "admin"
  Given Templates project exists for the "BioSistemika Process" team
  And "nonadmin@myorg.com" is signed in with "mypassword1234"

@javascript
Scenario: Unsuccessful add Text result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And WAIT
 And I click "Add" button
 Then I should see "can't be blank"
 And I click "Cancel" button

@javascript
Scenario: Successful add text result with Text name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 Then I should see "LJ ZOO"

@javascript
Scenario: Successful add Text result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "Vse to pa zaradi botra petelina, bog mu daj zdravje!" in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!"

@javascript
Scenario: Successful edit Text task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I click "fa-pencil-alt" icon
 And I fill in "ZOO" in "#result_name" field
 And I fill in "Vse to pa zaradi botra petelina!" in "#result_text_attributes_textarea" rich text editor field
 And I click "Save" button
 Then I should see "Vse to pa zaradi botra petelina!"

@javascript
Scenario: Successful add comment to a Text task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 Then I should see "I was on Triglav one summer."

@wip
Scenario: Unsuccessful add comment to a Text task result BUG!!!!!
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I fill in "" in "message" textarea field
 And confirm with ENTER key to "#message"
 And I click "fa-paper-plane" icon
 Then I should see "can't be blank"

@javascript
Scenario: Successful edit comment to a Text task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I click element with css ".comment-container"
 And I change comment "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more." of "#message"
 And I click "fa-save" icon
 Then I should see "I was on Triglav one summer and I do not have plans to go once more."

@javascript
Scenario: Unsuccessful edit comment to a Text task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I click element with css ".comment-container"
 And I change comment "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more." of "#message"
 And I click "fa-times" icon
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Unsuccessful delete comment to a Text task resultGiven I am on Task results page
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I hover over comment
 And I click "fa-trash" icon
 And I click to Cancel on confirm dialog
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Successful delete comment to a Text task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I hover over comment
 And I click "fa-trash" icon
 And I click to OK on confirm dialog
 And WAIT
 And I should not see "I was on Triglav one summer."

@javascript
Scenario: Successful archive text result with Text name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 Then I should see "Successfully archived text result in task Experiment design" flash message

@wip
Scenario: Unsuccessful add Table result ##########this one doesnt work
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 Then I should see "can't be blank"
 And I click "Cancel" button

@javascript
Scenario: Successful add table result with Table name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I fill in "ZOO" in "#result_name" field
 And I click on table cell one
 And I input "Živali pa so se odpravile dalje po svetu." in cell
 And I click "Add" button
 Then I should see "Živali pa so se odpravile dalje po svetu."

@javascript
Scenario: Successful add Table result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click on table cell one
 And I input "Vse to pa zaradi botra petelina, bog mu daj zdravje!" in cell
 And I click "Add" button
 Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!"

@javascript
Scenario: Successful edit Table task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I fill in "ZOO" in "#result_name" field
 And I click on table cell one
 And I input "Živali pa so se odpravile dalje po svetu." in cell
 And I click "Add" button
 And I click "fa-pencil-alt" icon
 And I fill in "LJ ZOO" in "#result_name" field
 And I click on table cell one
 And I input "Vse to pa zaradi botra petelina, bog mu daj zdravje!" in cell
 And I click "Save" button
 Then I should see "Vse to pa zaradi botra petelina, bog mu daj zdravje!"

@javascript
Scenario: Successful add comment to a Table task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Successful edit comment to a Table task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I click element with css ".comment-container"
 And I click element with css ".comment-container"
 And I change comment "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more." of "#message"
 And I click "fa-save" icon
 Then I should see "I was on Triglav one summer and I do not have plans to go once more."

@javascript
Scenario: Unsuccessful edit comment to a Table task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I click element with css ".comment-container"
 And I change comment "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more." of "#message"
 And I click "fa-times" icon
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Unsuccessful delete comment to a Table task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I hover over comment
 And I click "fa-trash" icon
 And I click to Cancel on confirm dialog
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Successful delete comment to a Table task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I hover over comment
 And I click "fa-trash" icon
 And I click to OK on confirm dialog
 Then I should not see "I was on Triglav one summer."

@javascript
Scenario: Successful archive Table result with Table name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 Then I should see "Successfully archived table result in task Experiment design" flash message

@wip
Scenario: Unsuccessful add File result #doesnt work
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I click "Add" button
 Then I should see File "can't be blank"
 And I click "Cancel" button

@javascript
Scenario: Successful add File result with File name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And WAIT
 Then I should see "MED"

@javascript
Scenario: Successful add File result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I click "Add" button
 And WAIT
 Then I should see "Moon"

@wip
Scenario: Successful edit File result with File name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I click "fa-pencil-alt" icon
 And I fill in "STAR ZOO" in "#result_name" field
 And I click "Save" button
 Then I should see "STAR ZOO"

@javascript
Scenario: Successful add comment to a File task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Successful edit comment to a File task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I click element with css ".comment-container"
 And I change comment "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more." of "#message"
 And I click "fa-save" icon
 Then I should see "I was on Triglav one summer and I do not have plans to go once more."

@javascript
Scenario: Unsuccessful edit comment to a File task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I click element with css ".comment-container"
 And I change comment "I was on Triglav one summer." with "I was on Triglav one summer and I do not have plans to go once more." of "#message"
 And I click "fa-times" icon
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Unsuccessful delete comment to a File task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I hover over comment
 And I click "fa-trash" icon
 And I click to Cancel on confirm dialog
 Then I should see "I was on Triglav one summer."

@javascript
Scenario: Successful delete comment to a File task result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I fill in "I was on Triglav one summer." in "message" textarea field
 And I click "fa-paper-plane" icon
 And WAIT
 And I hover over comment
 And I click "fa-trash" icon
 Then I click to OK on confirm dialog

@javascript
Scenario: Successful archive File result with File name
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 Then I should see "Successfully archived file result in task Experiment design" flash message

@javascript
Scenario: Download archived Text result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 And WAIT
 And I am on Task archive page
 And I click button with id "dropdownMenu1"
 Then I click on "Download" within dropdown menu
 And I delete downloaded file "LJ ZOO.txt"
 #no notification can be found

@javascript
Scenario: Download archived Table result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I fill in "Test table" in "#result_name" field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 And WAIT
 And I am on Task archive page
 And I click button with id "dropdownMenu1"
 Then I click on "Download" within dropdown menu
 And I delete downloaded file "Test table.txt"
 #no notification can be found

@javascript
Scenario: Download archived File result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 And WAIT
 And I am on Task archive page
 And I click button with id "dropdownMenu1"
 And I click on "View" within dropdown menu
 Then I click element with css ".file-download-link"
 And I delete downloaded file "Moon.png"
 #no notification can be found

@javascript
Scenario: Delete archived Text result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Text" within dropdown menu
 And I fill in "LJ ZOO" in "#result_name" field
 And I fill in "Živali pa so se odpravile dalje po svetu." in "#result_text_attributes_textarea" rich text editor field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 And WAIT
 And I am on Task archive page
 And I click button with id "dropdownMenu1"
 And I click on "Delete" within dropdown menu
 And I click to OK on confirm dialog
 Then I should see "Sucessfully removed result LJ ZOO from task Experiment design." flash message

@javascript
Scenario: Delete archived Table result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "Table" within dropdown menu
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 And WAIT
 And I am on Task archive page
 And I click button with id "dropdownMenu1"
 Then I click on "Delete" within dropdown menu
 And I click to OK on confirm dialog
 Then I should see "Sucessfully removed result from task Experiment design." flash message

@javascript
Scenario: Delete archived File result
 Given I am on Task results page
 And I click "Add new result" button
 And I click on "File" within dropdown menu
 And I attach file "Moon.png" to the drag-n-drop field
 And I fill in "MED" in "div.form-group:nth-child(1) > input:nth-child(2)" field
 And I click "Add" button
 And I click "fa-briefcase" icon
 And I click to OK on confirm dialog
 And WAIT
 And I am on Task archive page
 And I click button with id "dropdownMenu1"
 And I click on "Delete" within dropdown menu
 And I click to OK on confirm dialog
 Then I should see "Sucessfully removed result MED from task Experiment design." flash message
