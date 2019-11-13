When(/^I click "(.+)" button$/) do |button|
  click_button(button)
end

Then("I trigger click {string}") do |string|
  page.execute_script("$('#{string}').trigger('click')")
end

Given(/^Show me the page$/) do
  save_and_open_page
end

Then(/^I should be redirected to the homepage$/) do
  current_path.should =~ /^\/$/
end

Given(/^I click "(.+)" link$/) do |link|
  click_link link
end

Given(/^I click first "(.+)" link$/) do |link_text|
  first(:link, link_text).click
end

Given(/^I click "(.+)" link within "(.+)"$/) do |link, element|
  within(element) do
    click_link link
  end
end

Then(/^I click "(.+)" link within dropdown menu$/) do |link|
  within('.dropdown-menu') do
    click_link link
  end
end

Then(/^I should see "(.+)"$/) do |text|
  wait_for_ajax
  expect(page).to have_content(text)
end

Then(/^I should be on homepage$/) do
  expect(page).to have_current_path(root_path)
end

Given(/^the "([^"]*)" team exists$/) do |team_name|
  FactoryBot.create(:team, name: team_name)
end

Given(/^Demo project exists for the "([^"]*)" team$/) do |team_name|
  team = Team.find_by_name(team_name)
  user = team.user_teams.where(role: :admin).take.user
  seed_demo_data(user, team)
end

Given(/^I'm on the home page of "([^"]*)" team$/) do |team_name|
  team = Team.find_by_name(team_name)
  @current_user.update_attribute(:current_team_id, team.id)
  visit root_path
end

Given(/^"([^"]*)" is in "([^"]*)" team as a "([^"]*)"$/) do |user_email, team_name, role|
  team = Team.find_by_name(team_name)
  user = User.find_by_email(user_email)
  FactoryBot.create(:user_team, user: user,
                    team: team, role:
                    UserTeam.roles.fetch(role))
end

Then(/^I attach a "([^"]*)" file to "([^"]*)" field$/) do |file, field_id|
  wait_for_ajax
  find(field_id, :visible => false).attach_file(Rails.root.join('features', 'assets', file))
  # "expensive" operation needs some time :=)
  sleep(0.5)
end

Then(/^I should see "([^"]*)" error message$/) do |message|
  wait_for_ajax
  expect(page).to have_content(message)
end

Then(/^I click on "([^"]*)"$/) do |button|
  click_on button
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

Then(/^I click on Edit on "([^"]*)" input field$/) do |container_id|
  wait_for_ajax
  within(container_id) do
    find('[data-action="edit"]').click
  end
end

Then(/^I fill in "([^"]*)" in "([^"]*)" input field$/) do |text, input_id|
  page.find("#{input_id} input[type=\"text\"]").set(text)
end

Then(/^I fill in "([^"]*)" in "([^"]*)" rich text editor field$/) do |text, input_id|
  within_frame(find(input_id + '_ifr')) do
    find('#tinymce').set(text)
  end
end

Then(/^I fill in "([^"]*)" in "([^"]*)" field$/) do |text, input_id|
  page.find(input_id).set(text)
end

Then(/^I should see "([^"]*)" in "([^"]*)" input field$/) do |text, container_id|
  container = page.find(container_id)
  expect(container).to have_xpath("//input[@value='#{text}']")
end

Given("I click {string} icon") do |id|
  find(:css, id).click
end

Then(/^(?:|I )click on "([^"]*)" element$/) do |selector|
  find(selector).click
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

Then("I wait for {int} sec") do |sec|
  sleep sec
end

Given('default screen size') do
  page.driver.browser.manage.window.resize_to(1920, 1080) if defined?(page.driver.browser.manage)
end
