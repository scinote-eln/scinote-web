When(/^I click "(.+)" button$/) do |button|
  click_on(button)
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

Given(/^I click "(.+)" link within "(.+)"$/) do |link, element|
  within("##{element}") do
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
  FactoryGirl.create(:team, name: team_name)
end

Given(/^I'm on the home page of "([^"]*)" team$/) do |team_name|
  team = Team.find_by_name(team_name)
  @current_user.update_attribute(:current_team_id, team.id)
  visit root_path
end

Given(/^"([^"]*)" is in "([^"]*)" team as a "([^"]*)"$/) do |user_email, team_name, role|
  team = Team.find_by_name(team_name)
  user = User.find_by_email(user_email)
  FactoryGirl.create( :user_team, user: user,
                                  team: team,
                                  role: UserTeam.roles.fetch(role))
end

Then(/^I attach a "([^"]*)" file to "([^"]*)" field$/) do |file, field_id|
  wait_for_ajax
  attach_file(field_id, Rails.root.join('features', 'assets', file))
  # "expensive" operation needs some time :=)
  sleep(0.3)
end

Then(/^I should see "([^"]*)" error message under "([^"]*)" field$/) do |message, field_id|
  parent = find_by_id(field_id).first(:xpath, './/..')
  expect(parent).to have_content(message)
end

Then(/^I click on "([^"]*)"$/) do |button|
  click_on button
end

Then(/^I click on image within "([^"]*)" element$/) do |container|
  within(container) do
    find('img').click
  end
  wait_for_ajax
end

Then(/^I should see "([^"]*)" flash message$/) do |message|
  wait_for_ajax
  expect(find_by_id('alert-flash')).to have_content(message)
end

Then(/^I click on Edit on "([^"]*)" input field$/) do |container_id|
  wait_for_ajax
  container = page.find_by_id(container_id)
  within(container) do
    find('button').click
  end
end

Then(/^I fill in "([^"]*)" in "([^"]*)" input field$/) do |text, container_id|
  container = page.find_by_id(container_id)
  container.find('input').set(text)
end

Then(/^I should see "([^"]*)" in "([^"]*)" input field$/) do |text, container_id|
  container = page.find_by_id(container_id)
  expect(container).to have_xpath("//input[@value='#{text}']")
end
