Given(/^the following users are registered$/) do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:user, hash)
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

Given(/^is signed in with "([^"]*)", "([^"]*)"$/) do |email, password|
  visit '/users/sign_in'
  fill_in 'user_email', with: email
  fill_in 'user_password', with: password
  click_button 'Log in'
  @current_user = User.find_by_email(email)
end
