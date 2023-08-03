# frozen_string_literal: true

Given(/^the following users are registered:$/) do |table|
  table.hashes.each do |hash|
    team_name = hash.delete 'team'
    team_role = hash.delete 'role'
    user = FactoryBot.create(:user, hash)
    team = FactoryBot.create(:team, name: team_name, users: [user])
    User.find_by(email: hash.fetch('email')).confirm
  end
end

Then('I click {string} button') do |button|
  sci_click_on_button(text: button)
end

Then('I click {string} icon') do |icon_class|
  sci_click_on_icon(icon_class: icon_class)
end

Given('I click {string} button at position {int}') do |button, position|
  sci_click_on_button(text: button, position: position)
end

Then('I click {string} icon at position {int}') do |icon_class, position|
  sci_click_on_icon(icon_class: icon_class, position: position)
end

Then('I click {string} icon at position {int} within {string}') do |icon_class, position, container|
  sci_click_on_icon(icon_class: icon_class, position: position, container: container)
end

Then('I click {string} link') do |link|
  click_link link
end

Then('I click {string} link within {string}') do |link, container|
  within container do
    click_link link
  end
end

Then('I click element with css {string}') do |selector|
  find(selector).click
end

Given('I click button with id {string}') do |button1|
  find('.btn', id: button1).click
end

Then('I trigger click {string}') do |string|
  page.execute_script("$('#{string}').trigger('click')")
end

Then(/^I should be redirected to the homepage$/) do
  current_path.should =~ %r{^/$}
end

Given(/^I click first "(.+)" link$/) do |link_text|
  first(:link, link_text).click
end

Then(/^I click on "(.+)" within dropdown menu$/) do |text|
  within('.dropdown.open .dropdown-menu, .dropdown-menu.open') do
    find('li', text: text).click
  end
end

Then(/^I should see "(.+)"$/) do |text|
  wait_for_ajax
  expect(page).to have_content(text)
end

Then('I should not see {string}') do |text6|
  wait_for_ajax
  expect(page).not_to have_content(text6)
end

Then(/^I should be on homepage$/) do
  expect(page).to have_current_path(root_path)
end

Given(/^the "([^"]*)" team exists$/) do |team_name|
  FactoryBot.create(:team, name: team_name)
end

Given(/^Templates project exists for the "([^"]*)" team$/) do |team_name|
  team = Team.find_by(name: team_name)
  TemplatesService.new.schedule_creation_for_user(user)
end
Given(/^I'm on the projects page of "([^"]*)" team$/) do |team_name|
  team = Team.find_by(name: team_name)
  @current_user.update(current_team_id: team.id)
  visit projects_path
end

Given(/^"([^"]*)" is in "([^"]*)" team as a "([^"]*)"$/) do |user_email, team_name, role|
  team = Team.find_by(name: team_name)
  user = User.find_by(email: user_email)
end

Then(/^I attach a "([^"]*)" file to "([^"]*)" field$/) do |file, field_id|
  wait_for_ajax
  find(field_id, visible: false).attach_file(Rails.root.join('features', 'assets', file))
  # "expensive" operation needs some time :=)
  sleep(0.5)
end

Then(/^I should see "([^"]*)" error message$/) do |message|
  wait_for_ajax
  expect(page).to have_content(message)
end

Then(/^I click on image within "([^"]*)" element$/) do |container|
  sleep 0.5
  within(container) do
    find('img').click
  end
  wait_for_ajax
end

Then(/^I should see "([^"]*)" flash message$/) do |message|
  wait_for_ajax
  expect(find('.alert')).to have_content(message)
end

Then(/^I fill in "([^"]*)" in "([^"]*)" input field$/) do |text, input_id|
  page.find("#{input_id} input[type=\"text\"]").set(text)
end

Then(/^I fill in "([^"]*)" in "([^"]*)" rich text editor field$/) do |text, input_id|
  within_frame(find(input_id + '_ifr')) do
    find('#tinymce').set(text)
  end
end

Then('I fill in {string} to {string} field of {string} modal window') do |value, field, modal|
  page.find('.modal-content', text: modal).find_field(field, with: '').set(value)
end

Then('I change {string} with {string} of field {string} of {string} window') do |old_value, new_value, field, modal|
  page.find('.modal-content', text: modal).find_field(field, with: old_value).set(new_value)
end

Then(/^I fill in "([^"]*)" in "([^"]*)" field$/) do |text, input_id|
  page.find(input_id).set(text)
end

Then(/^I should see "([^"]*)" in "([^"]*)" input field$/) do |text, container_id|
  container = page.find(container_id)
  expect(container).to have_xpath("//input[@value='#{text}']")
end

Then(/^I attach file "([^"]*)" to the drag-n-drop field$/) do |file_name|
  find('#drag-n-drop-assets', visible: false).send_keys(Rails.root.join('features', 'assets', file_name))
end

Then(/^I change "([^"]*)" with "([^"]*)" in "([^"]*)" input field$/) do |old_text, new_text, container_id|
  wait_for_ajax
  container = page.find_by_id(container_id)
  expect(container).to have_xpath("//input[@value='#{old_text}']")
  container.find('input').set(new_text)
end

Then(/^I fill in "([^"]*)" in "([^"]*)" textarea field$/) do |text, textarea_id|
  textarea = page.find_by_id(textarea_id)
  textarea.set(text)
end

Then(/^I change "([^"]*)" with "([^"]*)" in "([^"]*)" textarea field$/) do |old_text, new_text, textarea_id|
  textarea = page.find_by_id(textarea_id)
  expect(textarea).to have_content(old_text)
  textarea.set(new_text)
end

Then(/^I should not see "([^"]*)" on "([^"]*)" element$/) do |text, element|
  wait_for_ajax
  expect(find(element)).not_to have_content(text)
end

Then(/^I should see "([^"]*)" on "([^"]*)" element$/) do |text, element|
  wait_for_ajax
  expect(find(element)).to have_content(text)
end

Then('I wait for {int} sec') do |sec|
  sleep sec
end

Given('default screen size') do
  page.driver.browser.manage.window.resize_to(1920, 1080) if defined?(page.driver.browser.manage)
end

Given('default screen size2') do
  page.driver.browser.manage.window.resize_to(1600, 900) if defined?(page.driver.browser.manage)
end

Then('I make screenshot') do
  page.execute_script 'window.scrollTo(0,0)'
  page.driver.save_screenshot 'screenshot.png'
end

Given('I click to Cancel on confirm dialog') do
  page.driver.browser.switch_to.alert.dismiss
end

Given('I click to OK on confirm dialog') do
  page.driver.browser.switch_to.alert.accept
end

Then('confirm with ENTER key to {string}') do |element| # More clear name of action?
  page.find(element.to_s).native.send_keys(:enter)
end

Then('I hover over comment') do
  find('.content-placeholder').hover
end

Then('I hover over element with css {string}') do |string|
  find(string.to_s).hover
end

Then('WAIT') do
  wait_for_ajax
end

Then('I fill bootsrap tags input with {string}') do |value|
  find('.bootstrap-tagsinput > input[type="text"]').set(value)
end

Then('I delete downloaded file {string}') do |file_name|
  sleep 3
  FileUtils.rm_f(Rails.root.join(file_name))
end
