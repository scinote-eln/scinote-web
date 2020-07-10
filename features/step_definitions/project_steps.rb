# frozen_string_literal: true

Given(/^I click on team switcher$/) do
  find('#team-switch').click
end

Given('I click to {string} in team dropdown menu') do |team|
  find('#team-switch .change-team', text: team).click
end

Given('My profile page of current user') do
  visit(edit_user_registration_path)
end

Then('I am on Projects page of {string} team of current user') do |team|
  check_active_team(team)
  expect(page).to have_selector '.nav-name', text: team
end

Then('I am on Protocols page of {string} team of current user') do |team|
  check_active_team(team)
  expect(page).to have_selector 'a', text: 'Team protocols'
end

Then('I am on Inventories page of {string} team of current user') do |team|
  check_active_team(team)
  expect(page).to have_selector 'a', text: 'New Inventory'
end

Then('I am on Reports page of {string} team of current user') do |team|
  check_active_team(team)
  expect(page).to have_selector 'a', text: 'New report'
end

Then('I am on Activities page of {string} team of current user') do |team|
  check_active_team(team)
  expect(page).to have_selector '.ga-title', text: 'Global activities'
end
