When(/^I click "(.+)" button$/) do |button|
  click_on button
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

Then(/^I attach a "([^"]*)" file to "([^"]*)" field$/) do |file, field|
  attach_file(field, Rails.root.join('features', 'assets', file))
end

Then(/^I should see "([^"]*)" error message under "([^"]*)" field$/) do |message, field|
  parent = find(field).first(:xpath, './/..')
  expect(parent).to have_content(message)
end

Then(/^I click on "([^"]*)"$/) do |button|
  click_on button
end

Then(/^I click on image within "([^"]*)" element$/) do |container|
  within(container) do
    find('img').click
  end
end

Then(/^I select a Star\.png file$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see "([^"]*)" flash message$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I click to Edit button under Full name field$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I fill in "([^"]*)"$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I click to Update button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see "([^"]*)" in Full name field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I click to Edit button under Initials field$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I click to Edit button under Email field$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I Change "([^"]*)" with "([^"]*)"$/) do |arg1, arg2|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I fill in "([^"]*)" in Current password field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see "([^"]*)" in Email field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I click to Edit button under Password field$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I fill in "([^"]*)" in Current pasword field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I fill in "([^"]*)" in New pasword field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I fill in "([^"]*)" in New pasword confiramtion field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see "([^"]*)" flash message under New password field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see "([^"]*)" flash message under New password confiramtion field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should see "([^"]*)" flash message under Current password field$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end
