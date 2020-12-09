# feature/protocol manage. feature
Feature: Protocol manage
  As a member of a project
  I want to add / change/ save protocol to a task / protocol management

Background:
Given the following users is registered:
 | name                 | email              | password        | team                 | role        |
 |Karli Novak (creator)| nonadmin@myorg.com | mypassword1234  | BioSistemika Process | Administrator|
And the following file:
 | file          | size     |
 | Moon.png      | 0.5 MB   |
 | Star.png      | 0.5 MB   |

 Scenario: Successful add new tag to a task
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Tags" icon
   Then I click to "Create new tag" button to "Manage tags for ZOO" modal window
   And I click to "Edit tag" icon to "New tag" tag
   Then I change "New tag" tag name to "Sky" tag name
   And I click to "Edit tag" icon to "Sky" tag
   And I click to "blue" square
   And I click on "Save tag" icon
   Then I should see blue "Sky" tag in "Showing tags of task ZOO" list
   And I click on "Close" button
   Then I should see blue "Sky" tag on "Tags:" line

 Scenario: Successful change a tag to a task
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Tags" icon
   Then I click to "Create new tag" button to "Manage tags for ZOO" modal window
   And I click to "Edit tag" icon to "New tag" tag
   Then I change "New tag" tag name to "Star" tag name
   And I click to "Edit tag" icon to "Star" tag
   And I click to "red" square
   And I click on "Save tag" icon
   Then I should see red "Star" tag in "Showing tags of task ZOO" list
   And I click to "X" icon of a blue "Sky" tag to "Remove tag from task ZOO"
   Then blue "Sky" tag is removed from "Showing tags of task ZOO" list
   And I click on "Close" button
   Then I should see red "Star" tag on "Tags:" line

 Scenario: Successful add a tag to a task
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Tags" icon
   Then I click to "Sky" tag from drop down menu
   And I click on "+Add tag" button
   Then I should see blue "Sky" tag in "Showing tags of task ZOO" list
   And I click on "Close" button
   Then I should see red "Star" tag on "Tags:" line
   Then I should see blue "Sky" tag on "Tags:" line

 Scenario: Successful change a tag name and tag color
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Tags" icon
   Then I click to "Create new tag" button to "Manage tags for ZOO" modal window
   And I click to "Edit tag" icon to "Star" tag
   Then I change "Star" tag name to "Moon" tag name
   And I click to "Edit tag" icon to "Moon" tag
   And I click to "pink" square
   And I click on "Save tag" icon
   Then I should see pink "Moon" tag in "Showing tags of task ZOO" list
   And I click on "Close" button
   Then I should see pink "Moon" tag on "Tags:" line

 Scenario: Successful delete a tag
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Tags" icon
   Then I click to "Permanently delete tag from all tasks" icon to "Star" tag
   And I click on "Close" button
   Then I should see red "Sky" tag on "Tags:" line

 Scenario: Successful add a due date
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Due date:" icon
   And I click to "26.9.2018" in Due date field of a "Edit task ZOO due date" modal window
   And I click on "Update" button
   Then I should see "26.9.2018" due date on "Due date:" line

 Scenario: Successful remove a due date
   Given TASK page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Due date:" icon
   And I click to "X" at the end of Due date field of a "Edit task ZOO due date" modal window
   And I click on "Update" button
   Then I should see "not set" due date on "Due date:" line

 Scenario: Successful add description
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "i" icon description of a "ZOO" task
   Then I fill in "I was on Triglav one summe.r" to Desription field of "Edit task ZOO description" modal window
   And I click on "Update" button
   Then I should see "I was on Triglav one summer" description on "i" line

 Scenario: Successful change description
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "i" icon description of a "ZOO" task
   Then I change "I was on Triglav one summer." desription with "I will go to Krn one day." desription of "Edit task ZOO description" modal window
   And I click on "Update" button

 Scenario: Successful Complete task
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Complete task" button
   Then I should see "Task completed" description on "Status:" line
   Then I should see grey "Uncomplete task" button

 Scenario: Successful Uncomplete task
   Given RESULTS page of a "Control" task of "qPCR" experiment of a "Protein" project of a Karli Novak user
   And I click to "Uncomplete task" button
   Then I should see "In progress" description on "Status:" line
   Then I should see green "Complete task" button
