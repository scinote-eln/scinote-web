<<<<<<< HEAD
<<<<<<< HEAD
# frozen_string_literal: true
=======
Given(/^I'm on the Protocols page of a "([^"]*)" task$/) do |task_name|
  task = MyModule.find_by_name(task_name)
  visit protocols_my_module_path(task)
end
>>>>>>> Initial commit of 1.17.2 merge
=======
# frozen_string_literal: true
>>>>>>> Pulled latest release

Then(/^I should see "([^"]*)" attachment on "([^"]*)" step$/) do |file, step_name|
  wait_for_ajax
  expect(find('.step', text: step_name)).to have_content(file)
end
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Pulled latest release

Then(/^I'm opening protocol section$/) do
  find(:css, '.task-section-caret[aria-controls="protocol-container"]').click
end

Then("I select {string} color") do |color1|
  find("[data-color='#{color1}']").click
end

Then('I click on Edit sign of {string} tag') do |text1|
  page.find("[data-name='#{text1}']").find('.edit-tag-link').click
end

Given('I click on {string} tag button') do |button2|
  find('.btn', text: button2, match: :first).click
end
<<<<<<< HEAD
=======
>>>>>>> Initial commit of 1.17.2 merge
=======
>>>>>>> Pulled latest release
