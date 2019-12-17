# frozen_string_literal: true

Given(/^I'm on the Protocols page of a "([^"]*)" task$/) do |task_name|
  task = MyModule.find_by(name: task_name)
  visit protocols_my_module_path(task)
end

Then(/^I should see "([^"]*)" attachment on "([^"]*)" step$/) do |file, step_name|
  wait_for_ajax
  expect(find('.step', text: step_name)).to have_content(file)
end

Then('I select {string} color') do |color1|
  find("[data-color='#{color1}']").click
end

Then('I click on Edit sign of {string} tag') do |text1|
  page.find("[data-name='#{text1}']").find('.edit-tag-link').click
end

Given('I click on {string} tag button') do |button2|
  find('.btn', text: button2, match: :first).click
end

Given('task page of Experiment design') do
  visit '/modules/1/protocols'
end
