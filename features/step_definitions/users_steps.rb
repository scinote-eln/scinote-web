Given(/^the following users are registered$/) do |table|
  table.hashes.each do |hash|
    FactoryBot.create(:user, hash)
    User.find_by_email(hash.fetch('email')).confirm
  end
end

Given(/^I visit the sign up page$/) do
  visit new_user_registration_path
end

Then(/^I fill the sign up form with$/) do |table|
  table.hashes.each do |hash|
    hash.each do |k, v|
      fill_in k, with: v
    end
  end
end

Given(/^"([^"]*)" is signed in with "([^"]*)"$/) do |email, password|
  visit '/users/sign_in'
  fill_in 'user_email', with: email
  fill_in 'user_password', with: password
  click_button 'Log in'
  @current_user = User.find_by_email(email)
end

Given("I am on Sign in page") do
  visit new_user_session_path
end

Given("I am on reset password page") do
  visit new_user_password_path
end

Given("I click on Reset Password link in the reset password email for user {string}") do |email|
  visit new_user_password_path
  fill_in 'user_email', with: email
  click_button 'Reset password'

  Delayed::Worker.new.work_off
  sleep 1
  open_email(email)
  current_email.click_link 'Change my password'
end

Then("I should be on Change your password page") do
  expect(page).to have_current_path(edit_user_password_path, ignore_query: true)
end

Given(/^I am on Log in page$/) do
  visit '/users/sign_in'
end

Then(/^I fill in Email "([^"]*)" and Password "([^"]*)"$/) do |email, password|
  fill_in 'user_email', with: email
  fill_in 'user_password', with: password
end

Given("I am on the home page of Biosistemika Process team") do
  visit '/projects'
end

Given("I am on task page of Biosistemika Process team") do
  visit '/modules/1/protocols'
end

