# frozen_string_literal: true

Then(/^I should see "([^"]*)" attachment on "([^"]*)" step$/) do |file, step_name|
  wait_for_ajax
  expect(find('.step', text: step_name)).to have_content(file)
end

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
