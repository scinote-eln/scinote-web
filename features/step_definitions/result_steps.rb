# frozen_string_literal: true

Given(/^I'm on the Results page of a "([^"]*)" task$/) do |task_name|
  task = MyModule.find_by(name: task_name)
  visit results_my_module_path(task)
end

Given(/^I click edit "(.+)" result icon$/) do |result_name|
  find('.panel-heading', text: result_name).find('.edit-result-asset').click
end

Then('I input {string} in cell') do |input|
  find('.handsontableInput').set(input)
end

Then('I click on table cell one') do
  find('.htCore tbody td', match: :first).double_click
end

Given('I am on Task archive page') do
  visit '/modules/1/archive'
end

Then('I change comment {string} with {string} of {string}') do |text1, text2, message_id|
  find(message_id.to_s, text: text1).set(text2)
end

Given('I am on Task results page') do
  visit '/modules/1/results'
end
