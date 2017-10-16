Then(/^I click on Avatar$/) do
  find('img.avatar').click
end

Given(/^I'm on the profile page$/) do
  # visit '/settings/account/profile' randomly rises an EOFError
  visit root_path
  find('img.avatar').click
  within('#user-account-dropdown') { click_link('Settings') }
end

Then(/^I click on Browse button$/) do
  find('input#user_avatar').click
end

Then(/^I change "([^"]*)" with "([^"]*)" email$/) do |prev_email, new_email|
  find(:xpath, "//input[@value='#{prev_email}']").set(new_email)
end

Then(/^I fill in "([^"]*)" in Current password field$/) do |password|
  find(:xpath, '//input[@id="settings_page.current_password"]').set(password)
end

Then(/^I fill in "([^"]*)" in New password field$/) do |password|
  find(:xpath, '//input[@id="settings_page.new_password"]').set(password)
end

Then(/^I fill in "([^"]*)" in New password confirmation field$/) do |password|
  find(:xpath,
       '//input[@id="settings_page.new_password_confirmation"]').set(password)
end
